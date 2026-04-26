defmodule Albuminum.Repo.Migrations.MigrateIdsToUuids do
  use Ecto.Migration

  # PRAGMA foreign_keys cannot be changed inside a transaction in SQLite.
  @disable_ddl_transaction true

  # Generates a v4 UUID string directly in SQLite.
  defp gen_uuid,
    do:
      "lower(hex(randomblob(4)))||'-'||lower(hex(randomblob(2)))||'-4'||lower(substr(hex(randomblob(2)),2))||'-'||substr('89ab',abs(random())%4+1,1)||lower(substr(hex(randomblob(2)),2))||'-'||lower(hex(randomblob(6)))"

  def up do
    execute "PRAGMA foreign_keys = OFF"

    # =========================================================================
    # Phase 1: Add TEXT UUID columns alongside existing integer PKs
    # =========================================================================

    execute "ALTER TABLE users ADD COLUMN new_id TEXT"
    execute "ALTER TABLE images ADD COLUMN new_id TEXT"
    execute "ALTER TABLE albums ADD COLUMN new_id TEXT"
    execute "ALTER TABLE tags ADD COLUMN new_id TEXT"
    execute "ALTER TABLE album_images ADD COLUMN new_id TEXT"
    execute "ALTER TABLE image_sources ADD COLUMN new_id TEXT"
    execute "ALTER TABLE album_shares ADD COLUMN new_id TEXT"
    execute "ALTER TABLE users_tokens ADD COLUMN new_id TEXT"
    execute "ALTER TABLE oauth_tokens ADD COLUMN new_id TEXT"

    # Populate UUIDs for all rows
    execute "UPDATE users SET new_id = #{gen_uuid()}"
    execute "UPDATE images SET new_id = #{gen_uuid()}"
    execute "UPDATE albums SET new_id = #{gen_uuid()}"
    execute "UPDATE tags SET new_id = #{gen_uuid()}"
    execute "UPDATE album_images SET new_id = #{gen_uuid()}"
    execute "UPDATE image_sources SET new_id = #{gen_uuid()}"
    execute "UPDATE album_shares SET new_id = #{gen_uuid()}"
    execute "UPDATE users_tokens SET new_id = #{gen_uuid()}"
    execute "UPDATE oauth_tokens SET new_id = #{gen_uuid()}"

    # =========================================================================
    # Phase 2: Add TEXT UUID FK columns, populate via subqueries
    # =========================================================================

    # Tables referencing users
    execute "ALTER TABLE albums ADD COLUMN new_user_id TEXT"
    execute "ALTER TABLE tags ADD COLUMN new_user_id TEXT"
    execute "ALTER TABLE users_tokens ADD COLUMN new_user_id TEXT"
    execute "ALTER TABLE oauth_tokens ADD COLUMN new_user_id TEXT"

    execute "UPDATE albums SET new_user_id = (SELECT new_id FROM users WHERE users.id = albums.user_id)"
    execute "UPDATE tags SET new_user_id = (SELECT new_id FROM users WHERE users.id = tags.user_id)"
    execute "UPDATE users_tokens SET new_user_id = (SELECT new_id FROM users WHERE users.id = users_tokens.user_id)"
    execute "UPDATE oauth_tokens SET new_user_id = (SELECT new_id FROM users WHERE users.id = oauth_tokens.user_id)"

    # Tables referencing albums and images
    execute "ALTER TABLE album_images ADD COLUMN new_album_id TEXT"
    execute "ALTER TABLE album_images ADD COLUMN new_image_id TEXT"
    execute "ALTER TABLE album_shares ADD COLUMN new_album_id TEXT"

    execute "UPDATE album_images SET new_album_id = (SELECT new_id FROM albums WHERE albums.id = album_images.album_id)"
    execute "UPDATE album_images SET new_image_id = (SELECT new_id FROM images WHERE images.id = album_images.image_id)"
    execute "UPDATE album_shares SET new_album_id = (SELECT new_id FROM albums WHERE albums.id = album_shares.album_id)"

    # Tables referencing images and tags
    execute "ALTER TABLE image_tags ADD COLUMN new_image_id TEXT"
    execute "ALTER TABLE image_tags ADD COLUMN new_tag_id TEXT"
    execute "ALTER TABLE image_sources ADD COLUMN new_image_id TEXT"

    execute "UPDATE image_tags SET new_image_id = (SELECT new_id FROM images WHERE images.id = image_tags.image_id)"
    execute "UPDATE image_tags SET new_tag_id = (SELECT new_id FROM tags WHERE tags.id = image_tags.tag_id)"
    execute "UPDATE image_sources SET new_image_id = (SELECT new_id FROM images WHERE images.id = image_sources.image_id)"

    # =========================================================================
    # Phase 3: Recreate tables with TEXT UUID PKs, in dependency order.
    # Pattern: rename old → _bak, create new with final name, copy, drop _bak.
    # This avoids any RENAME conflict on the new table.
    # =========================================================================

    # --- users ---
    execute "ALTER TABLE users RENAME TO users_bak"

    execute """
    CREATE TABLE users (
      id TEXT PRIMARY KEY NOT NULL,
      email TEXT NOT NULL COLLATE NOCASE,
      hashed_password TEXT,
      google_id TEXT,
      confirmed_at TEXT,
      inserted_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    """

    execute """
    INSERT INTO users (id, email, hashed_password, google_id, confirmed_at, inserted_at, updated_at)
    SELECT new_id, email, hashed_password, google_id, confirmed_at, inserted_at, updated_at
    FROM users_bak
    """

    execute "DROP TABLE users_bak"
    execute "CREATE UNIQUE INDEX users_email_index ON users (email)"
    execute "CREATE UNIQUE INDEX users_google_id_index ON users (google_id)"

    # --- images ---
    execute "ALTER TABLE images RENAME TO images_bak"

    execute """
    CREATE TABLE images (
      id TEXT PRIMARY KEY NOT NULL,
      filename TEXT,
      path TEXT,
      alt_text TEXT,
      caption TEXT,
      inserted_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    """

    execute """
    INSERT INTO images (id, filename, path, alt_text, caption, inserted_at, updated_at)
    SELECT new_id, filename, path, alt_text, caption, inserted_at, updated_at
    FROM images_bak
    """

    execute "DROP TABLE images_bak"

    # --- users_tokens (no updated_at) ---
    execute "ALTER TABLE users_tokens RENAME TO users_tokens_bak"

    execute """
    CREATE TABLE users_tokens (
      id TEXT PRIMARY KEY NOT NULL,
      user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      token BLOB NOT NULL,
      context TEXT NOT NULL,
      sent_to TEXT,
      authenticated_at TEXT,
      inserted_at TEXT NOT NULL
    )
    """

    execute """
    INSERT INTO users_tokens (id, user_id, token, context, sent_to, authenticated_at, inserted_at)
    SELECT new_id, new_user_id, token, context, sent_to, authenticated_at, inserted_at
    FROM users_tokens_bak
    """

    execute "DROP TABLE users_tokens_bak"
    execute "CREATE INDEX users_tokens_user_id_index ON users_tokens (user_id)"
    execute "CREATE UNIQUE INDEX users_tokens_context_token_index ON users_tokens (context, token)"

    # --- oauth_tokens ---
    execute "ALTER TABLE oauth_tokens RENAME TO oauth_tokens_bak"

    execute """
    CREATE TABLE oauth_tokens (
      id TEXT PRIMARY KEY NOT NULL,
      user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      provider TEXT NOT NULL,
      access_token BLOB NOT NULL,
      refresh_token BLOB,
      expires_at TEXT,
      scope TEXT,
      inserted_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    """

    execute """
    INSERT INTO oauth_tokens (id, user_id, provider, access_token, refresh_token, expires_at, scope, inserted_at, updated_at)
    SELECT new_id, new_user_id, provider, access_token, refresh_token, expires_at, scope, inserted_at, updated_at
    FROM oauth_tokens_bak
    """

    execute "DROP TABLE oauth_tokens_bak"
    execute "CREATE UNIQUE INDEX oauth_tokens_user_id_provider_index ON oauth_tokens (user_id, provider)"

    # --- albums ---
    execute "ALTER TABLE albums RENAME TO albums_bak"

    execute """
    CREATE TABLE albums (
      id TEXT PRIMARY KEY NOT NULL,
      name TEXT,
      description TEXT,
      user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      inserted_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    """

    execute """
    INSERT INTO albums (id, name, description, user_id, inserted_at, updated_at)
    SELECT new_id, name, description, new_user_id, inserted_at, updated_at
    FROM albums_bak
    """

    execute "DROP TABLE albums_bak"
    execute "CREATE INDEX albums_user_id_index ON albums (user_id)"

    # --- tags ---
    execute "ALTER TABLE tags RENAME TO tags_bak"

    execute """
    CREATE TABLE tags (
      id TEXT PRIMARY KEY NOT NULL,
      name TEXT NOT NULL,
      user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      inserted_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    """

    execute """
    INSERT INTO tags (id, name, user_id, inserted_at, updated_at)
    SELECT new_id, name, new_user_id, inserted_at, updated_at
    FROM tags_bak
    """

    execute "DROP TABLE tags_bak"
    execute "CREATE INDEX tags_user_id_index ON tags (user_id)"
    execute "CREATE UNIQUE INDEX tags_user_id_name_index ON tags (user_id, name)"

    # --- album_images ---
    execute "ALTER TABLE album_images RENAME TO album_images_bak"

    execute """
    CREATE TABLE album_images (
      id TEXT PRIMARY KEY NOT NULL,
      position INTEGER,
      album_id TEXT REFERENCES albums(id) ON DELETE CASCADE,
      image_id TEXT REFERENCES images(id) ON DELETE CASCADE,
      inserted_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    """

    execute """
    INSERT INTO album_images (id, position, album_id, image_id, inserted_at, updated_at)
    SELECT new_id, position, new_album_id, new_image_id, inserted_at, updated_at
    FROM album_images_bak
    """

    execute "DROP TABLE album_images_bak"
    execute "CREATE INDEX album_images_album_id_index ON album_images (album_id)"
    execute "CREATE INDEX album_images_image_id_index ON album_images (image_id)"

    # --- image_tags (composite PK, no auto-increment id) ---
    execute "ALTER TABLE image_tags RENAME TO image_tags_bak"

    execute """
    CREATE TABLE image_tags (
      image_id TEXT NOT NULL REFERENCES images(id) ON DELETE CASCADE,
      tag_id TEXT NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
      inserted_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      PRIMARY KEY (image_id, tag_id)
    )
    """

    execute """
    INSERT INTO image_tags (image_id, tag_id, inserted_at, updated_at)
    SELECT new_image_id, new_tag_id, inserted_at, updated_at
    FROM image_tags_bak
    """

    execute "DROP TABLE image_tags_bak"
    execute "CREATE INDEX image_tags_image_id_index ON image_tags (image_id)"
    execute "CREATE INDEX image_tags_tag_id_index ON image_tags (tag_id)"
    execute "CREATE UNIQUE INDEX image_tags_image_id_tag_id_index ON image_tags (image_id, tag_id)"

    # --- image_sources ---
    execute "ALTER TABLE image_sources RENAME TO image_sources_bak"

    execute """
    CREATE TABLE image_sources (
      id TEXT PRIMARY KEY NOT NULL,
      image_id TEXT NOT NULL REFERENCES images(id) ON DELETE CASCADE,
      provider TEXT NOT NULL,
      external_id TEXT NOT NULL,
      metadata TEXT,
      inserted_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    """

    execute """
    INSERT INTO image_sources (id, image_id, provider, external_id, metadata, inserted_at, updated_at)
    SELECT new_id, new_image_id, provider, external_id, metadata, inserted_at, updated_at
    FROM image_sources_bak
    """

    execute "DROP TABLE image_sources_bak"
    execute "CREATE INDEX image_sources_image_id_index ON image_sources (image_id)"
    execute "CREATE UNIQUE INDEX image_sources_provider_external_id_index ON image_sources (provider, external_id)"

    # --- album_shares ---
    execute "ALTER TABLE album_shares RENAME TO album_shares_bak"

    execute """
    CREATE TABLE album_shares (
      id TEXT PRIMARY KEY NOT NULL,
      token TEXT NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1,
      album_id TEXT NOT NULL REFERENCES albums(id) ON DELETE CASCADE,
      inserted_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    """

    execute """
    INSERT INTO album_shares (id, token, is_active, album_id, inserted_at, updated_at)
    SELECT new_id, token, is_active, new_album_id, inserted_at, updated_at
    FROM album_shares_bak
    """

    execute "DROP TABLE album_shares_bak"
    execute "CREATE UNIQUE INDEX album_shares_token_index ON album_shares (token)"
    execute "CREATE UNIQUE INDEX album_shares_album_id_index ON album_shares (album_id)"

    execute "PRAGMA foreign_keys = ON"
  end

  def down do
    raise Ecto.MigrationError, "Migration to UUIDs cannot be reversed. Restore from backup."
  end
end
