defmodule Albuminum.Gallery do
  @moduledoc """
  The Gallery context.

  Handles albums, images, and their relationships.
  All album operations are scoped to the current user.
  """

  import Ecto.Query, warn: false
  alias Albuminum.Repo
  alias Albuminum.Accounts.Scope
  alias Albuminum.Gallery.{Album, Image, AlbumImage}

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
