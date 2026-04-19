defmodule Albuminum.Gallery do
  @moduledoc """
  The Gallery context.

  Handles albums, images, and their relationships.
  All album operations are scoped to the current user.
  """

  import Ecto.Query, warn: false
  alias Albuminum.Repo
  alias Albuminum.Accounts.Scope
  alias Albuminum.Gallery.{Album, AlbumShare, Image, AlbumImage, ImageSource}

  # ============================================================================
  # Albums (scoped to user)
  # ============================================================================

  @doc """
  Returns albums for the current user.
  """
  def list_albums(%Scope{user: user}) do
    from(a in Album, where: a.user_id == ^user.id)
    |> Repo.all()
  end

  @doc """
  Gets album by ID, scoped to current user.
  Raises if album doesn't exist or doesn't belong to user.
  """
  def get_album!(%Scope{user: user}, id) do
    from(a in Album, where: a.id == ^id and a.user_id == ^user.id)
    |> Repo.one!()
  end

  @doc """
  Gets album with images preloaded, scoped to current user.
  """
  def get_album_with_images!(%Scope{} = scope, id) do
    scope
    |> get_album!(id)
    |> Repo.preload(album_images: :image)
  end

  @doc """
  Creates album for current user.
  """
  def create_album(%Scope{user: user}, attrs) do
    %Album{user_id: user.id}
    |> Album.changeset(attrs)
    |> Repo.insert()
  end

  def update_album(%Album{} = album, attrs) do
    album
    |> Album.changeset(attrs)
    |> Repo.update()
  end

  def delete_album(%Album{} = album) do
    Repo.delete(album)
  end

  def change_album(%Album{} = album, attrs \\ %{}) do
    Album.changeset(album, attrs)
  end

  # ============================================================================
  # Album Sharing
  # ============================================================================

  @doc """
  Gets the active share record for an album, if one exists.
  Returns nil if no share or share is inactive.
  """
  def get_album_share(%Album{id: album_id}) do
    case Repo.get_by(AlbumShare, album_id: album_id) do
      %AlbumShare{is_active: true} = share -> share
      _ -> nil
    end
  end

  @doc """
  Toggles sharing for an album.
  Creates share with token if none exists, otherwise toggles is_active.
  Token stays the same across toggles.
  Returns {:ok, share} with updated state.
  """
  def toggle_album_share(%Album{id: album_id}) do
    result =
      case Repo.get_by(AlbumShare, album_id: album_id) do
        nil ->
          # First time sharing - create with token
          %AlbumShare{}
          |> AlbumShare.changeset(%{
            album_id: album_id,
            token: generate_share_token(),
            is_active: true
          })
          |> Repo.insert()

        share ->
          # Toggle existing share
          share
          |> AlbumShare.changeset(%{is_active: !share.is_active})
          |> Repo.update()
      end

    case result do
      {:ok, _} -> broadcast_album_update(album_id)
      _ -> :ok
    end

    result
  end

  defp generate_share_token do
    :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
  end

  @doc """
  Gets an album by its share token.
  For public/unauthenticated access.
  Raises if token is invalid or share is inactive.
  """
  def get_album_by_share_token!(token) do
    share = Repo.get_by!(AlbumShare, token: token, is_active: true)
    Repo.get!(Album, share.album_id)
  end

  @doc """
  Gets an album with images by share token.
  For public/unauthenticated access.
  """
  def get_album_with_images_by_share_token!(token) do
    token
    |> get_album_by_share_token!()
    |> Repo.preload(album_images: :image)
  end

  # ============================================================================
  # Images (shared across all users)
  # ============================================================================

  def list_images do
    Repo.all(Image)
  end

  def get_image!(id), do: Repo.get!(Image, id)

  def create_image(attrs) do
    %Image{}
    |> Image.changeset(attrs)
    |> Repo.insert()
  end

  # ============================================================================
  # Album-Image Relationships
  # ============================================================================

  @doc """
  Adds image to album at end of current order.
  """
  def add_image_to_album(%Album{} = album, %Image{} = image) do
    next_position =
      from(ai in AlbumImage,
        where: ai.album_id == ^album.id,
        select: coalesce(max(ai.position), -1) + 1
      )
      |> Repo.one()

    result =
      %AlbumImage{}
      |> AlbumImage.changeset(%{
        album_id: album.id,
        image_id: image.id,
        position: next_position
      })
      |> Repo.insert()

    case result do
      {:ok, _} -> broadcast_album_update(album.id)
      _ -> :ok
    end

    result
  end

  @doc """
  Removes image from album.
  """
  def remove_image_from_album(%Album{} = album, %Image{} = image) do
    from(ai in AlbumImage,
      where: ai.album_id == ^album.id and ai.image_id == ^image.id
    )
    |> Repo.delete_all()

    broadcast_album_update(album.id)
    :ok
  end

  @doc """
  Reorders images in album. Takes list of image_ids in desired order.
  """
  def reorder_album_images(%Album{} = album, image_ids) when is_list(image_ids) do
    result =
      Repo.transaction(fn ->
        image_ids
        |> Enum.with_index()
        |> Enum.each(fn {image_id, position} ->
          from(ai in AlbumImage,
            where: ai.album_id == ^album.id and ai.image_id == ^image_id
          )
          |> Repo.update_all(set: [position: position])
        end)
      end)

    case result do
      {:ok, _} -> broadcast_album_update(album.id)
      _ -> :ok
    end

    result
  end

  @doc """
  Gets images not yet in album (for "add image" picker).
  Preloads source for grouping by provider.
  """
  def list_images_not_in_album(%Album{} = album) do
    subquery = from(ai in AlbumImage, where: ai.album_id == ^album.id, select: ai.image_id)

    from(i in Image, where: i.id not in subquery(subquery), preload: [:source])
    |> Repo.all()
  end

  @doc """
  Groups images by their source provider.
  Returns list of {label, images} tuples, ordered for display.
  Images without a source are grouped as "Sample Images".
  """
  def group_images_by_source(images) do
    images
    |> Enum.group_by(fn image ->
      case image.source do
        nil -> "sample"
        %ImageSource{provider: provider} -> provider
      end
    end)
    |> Enum.map(fn {key, imgs} -> {source_label(key), key, imgs} end)
    |> Enum.sort_by(fn {_label, key, _imgs} -> source_sort_order(key) end)
  end

  defp source_label("sample"), do: "Sample Images"
  defp source_label("google_photos"), do: "Google Photos"
  defp source_label("icloud"), do: "iCloud"
  defp source_label("onedrive"), do: "OneDrive"
  defp source_label(other), do: String.capitalize(other)

  defp source_sort_order("google_photos"), do: 0
  defp source_sort_order("icloud"), do: 1
  defp source_sort_order("onedrive"), do: 2
  defp source_sort_order("sample"), do: 99
  defp source_sort_order(_), do: 50

  # ============================================================================
  # External Image Sources (Google Photos, iCloud, etc.)
  # ============================================================================

  @doc """
  Finds existing image by external source, or creates new one.
  Returns {:ok, image} or {:error, changeset}.
  """
  def find_or_create_from_source(provider, external_id, attrs) do
    case get_image_by_source(provider, external_id) do
      %Image{} = image ->
        {:ok, image}

      nil ->
        create_image_with_source(provider, external_id, attrs)
    end
  end

  @doc """
  Gets image by external source provider and ID.
  """
  def get_image_by_source(provider, external_id) do
    from(i in Image,
      join: s in ImageSource,
      on: s.image_id == i.id,
      where: s.provider == ^provider and s.external_id == ^external_id
    )
    |> Repo.one()
  end

  @doc """
  Creates image with external source reference.
  """
  def create_image_with_source(provider, external_id, attrs) do
    Repo.transaction(fn ->
      with {:ok, image} <- create_image(attrs),
           {:ok, _source} <- create_image_source(image, provider, external_id, attrs[:metadata]) do
        Repo.preload(image, :source)
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  defp create_image_source(image, provider, external_id, metadata) do
    %ImageSource{}
    |> ImageSource.changeset(%{
      image_id: image.id,
      provider: provider,
      external_id: external_id,
      metadata: metadata || %{}
    })
    |> Repo.insert()
  end

  @doc """
  Imports Google Photos media item and adds to album.
  Downloads image locally to avoid baseUrl expiration.
  Avoids duplicates by checking external_id.
  """
  def import_google_photo_to_album(%Album{} = album, media_item, access_token) do
    external_id = media_item["id"]

    # Photo Picker API nests data in "mediaFile", Library API had it at top level
    media_file = media_item["mediaFile"] || %{}
    base_url = media_file["baseUrl"] || media_item["baseUrl"]

    # Guard against missing baseUrl
    if is_nil(base_url) or base_url == "" do
      {:error, :missing_base_url}
    else
      import_google_photo_with_url(album, media_item, external_id, base_url, access_token)
    end
  end

  defp import_google_photo_with_url(album, media_item, external_id, base_url, access_token) do
    media_file = media_item["mediaFile"] || %{}
    original_filename = media_file["filename"] || media_item["filename"] || "google_photo_#{external_id}"
    mime_type = media_file["mimeType"] || media_item["mimeType"] || "image/jpeg"

    # Download image from Google (=d for original size)
    download_url = "#{base_url}=d"

    case download_and_save_image(download_url, external_id, mime_type, access_token) do
      {:ok, local_path} ->
        attrs = %{
          filename: original_filename,
          path: local_path,
          metadata: %{
            "source" => "google_photos",
            "media_item_id" => external_id,
            "mime_type" => mime_type
          }
        }

        case find_or_create_from_source("google_photos", external_id, attrs) do
          {:ok, image} ->
            add_image_to_album(album, image)

          error ->
            error
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp download_and_save_image(url, external_id, mime_type, access_token) do
    require Logger
    Logger.debug("Downloading image: #{url}")

    case Req.get(url, auth: {:bearer, access_token}, max_redirects: 5, receive_timeout: 30_000) do
      {:ok, %Req.Response{status: 200, body: body}} when is_binary(body) ->
        # Generate unique filename
        ext = mime_type_to_ext(mime_type)
        filename = "#{external_id}#{ext}"
        uploads_dir = Path.join([:code.priv_dir(:albuminum), "static", "uploads"])
        file_path = Path.join(uploads_dir, filename)

        # Ensure directory exists
        File.mkdir_p!(uploads_dir)

        Logger.debug("Saving #{byte_size(body)} bytes to #{file_path}")

        case File.write(file_path, body) do
          :ok ->
            # Return web-accessible path
            {:ok, "/uploads/#{filename}"}

          {:error, reason} ->
            Logger.error("File write failed: #{inspect(reason)}")
            {:error, {:file_write, reason}}
        end

      {:ok, %Req.Response{status: status, body: body}} ->
        Logger.error("Download failed with status #{status}: #{inspect(body)}")
        {:error, {:download_failed, status}}

      {:error, reason} ->
        Logger.error("Download request failed: #{inspect(reason)}")
        {:error, {:download_failed, reason}}
    end
  end

  defp mime_type_to_ext("image/jpeg"), do: ".jpg"
  defp mime_type_to_ext("image/png"), do: ".png"
  defp mime_type_to_ext("image/gif"), do: ".gif"
  defp mime_type_to_ext("image/webp"), do: ".webp"
  defp mime_type_to_ext("image/heic"), do: ".heic"
  defp mime_type_to_ext("video/mp4"), do: ".mp4"
  defp mime_type_to_ext(_), do: ".jpg"

  # ============================================================================
  # PubSub
  # ============================================================================

  @doc """
  Broadcasts album update to subscribers.
  Used for realtime updates in public view.
  """
  def broadcast_album_update(album_id) do
    Phoenix.PubSub.broadcast(Albuminum.PubSub, "album:#{album_id}", {:album_updated, album_id})
  end

  @doc """
  Subscribes to album updates.
  """
  def subscribe_to_album(album_id) do
    Phoenix.PubSub.subscribe(Albuminum.PubSub, "album:#{album_id}")
  end
end
