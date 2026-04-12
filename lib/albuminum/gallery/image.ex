defmodule Albuminum.Gallery.Image do
  use Ecto.Schema
  import Ecto.Changeset

  alias Albuminum.Gallery.AlbumImage

  schema "images" do
    field :filename, :string
    field :path, :string

    # Association: Image can belong to many albums through AlbumImage
    has_many :album_images, AlbumImage

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(image, attrs) do
    image
    |> cast(attrs, [:filename, :path])
    |> validate_required([:filename, :path])
  end
end
