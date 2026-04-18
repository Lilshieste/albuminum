defmodule Albuminum.Repo.Migrations.AddGoogleOauth do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :google_id, :string
    end

    create unique_index(:users, [:google_id])

    create table(:oauth_tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :provider, :string, null: false
      add :access_token, :binary, null: false
      add :refresh_token, :binary
      add :expires_at, :utc_datetime
      add :scope, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:oauth_tokens, [:user_id, :provider])
  end
end
