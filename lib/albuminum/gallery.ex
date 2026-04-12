defmodule Albuminum.Gallery do
  @moduledoc """
  The Gallery context.

  Handles albums, images, and their relationships.
  """

  import Ecto.Query, warn: false
  alias Albuminum.Repo

  alias Albuminum.Gallery.{Album, Image, AlbumImage}

  # ============================================================================
  # Albums
  # ============================================================================

  def list_albums do
    Repo.all(Album)
  end

  def get_album!(id), do: Repo.get!(Album, id)

  @doc """
  Gets album with images preloaded, ordered by position.
  """
  def get_album_with_images!(id) do
    Album
    |> Repo.get!(id)
    |> Repo.preload(album_images: :image)
  end

  def create_album(attrs) do
    %Album{}
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
  # Images
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
    # Get next position (max position + 1, or 0 if empty)
    next_position =
      from(ai in AlbumImage,
        where: ai.album_id == ^album.id,
        select: coalesce(max(ai.position), -1) + 1
      )
      |> Repo.one()

    %AlbumImage{}
    |> AlbumImage.changeset(%{
      album_id: album.id,
      image_id: image.id,
      position: next_position
    })
    |> Repo.insert()
  end

  @doc """
  Removes image from album.
  """
  def remove_image_from_album(%Album{} = album, %Image{} = image) do
    from(ai in AlbumImage,
      where: ai.album_id == ^album.id and ai.image_id == ^image.id
    )
    |> Repo.delete_all()

    :ok
  end

  @doc """
  Reorders images in album. Takes list of image_ids in desired order.
  """
  def reorder_album_images(%Album{} = album, image_ids) when is_list(image_ids) do
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
  end

  @doc """
  Gets images not yet in album (for "add image" picker).
  """
  def list_images_not_in_album(%Album{} = album) do
    subquery = from(ai in AlbumImage, where: ai.album_id == ^album.id, select: ai.image_id)

    from(i in Image, where: i.id not in subquery(subquery))
    |> Repo.all()
  end
end
