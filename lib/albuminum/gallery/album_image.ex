defmodule Albuminum.Gallery.AlbumImage do
  use Ecto.Schema
  import Ecto.Changeset

  alias Albuminum.Gallery.{Album, Image}

  schema "album_images" do
    field :position, :integer

    # belongs_to replaces the raw :id fields with actual associations
    belongs_to :album, Album
    belongs_to :image, Image

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(album_image, attrs) do
    album_image
    |> cast(attrs, [:position, :album_id, :image_id])
    |> validate_required([:position, :album_id, :image_id])
    |> foreign_key_constraint(:album_id)
    |> foreign_key_constraint(:image_id)
  end
end
