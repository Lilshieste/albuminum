defmodule Albuminum.Gallery.Image do
  use Ecto.Schema
  import Ecto.Changeset

  alias Albuminum.Gallery.{AlbumImage, ImageSource}

  schema "images" do
    field :filename, :string
    field :path, :string

    has_many :album_images, AlbumImage
    has_one :source, ImageSource

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(image, attrs) do
    image
    |> cast(attrs, [:filename, :path])
    |> validate_required([:filename, :path])
  end
end
