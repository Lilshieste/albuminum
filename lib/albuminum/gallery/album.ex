defmodule Albuminum.Gallery.Album do
  use Ecto.Schema
  import Ecto.Changeset

  alias Albuminum.Gallery.{AlbumImage, Image}

  schema "albums" do
    field :name, :string
    field :description, :string

    # Association: Album has many images through AlbumImage join table
    # order_by on album_images.position handles display ordering
    has_many :album_images, AlbumImage, preload_order: [asc: :position]
    many_to_many :images, Image, join_through: AlbumImage

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(album, attrs) do
    album
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
  end
end
