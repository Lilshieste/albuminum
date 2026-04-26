defmodule Albuminum.Gallery.Image do
  use Ecto.Schema
  import Ecto.Changeset

  alias Albuminum.Gallery.{AlbumImage, ImageSource, Tag}

  @primary_key {:id, Albuminum.Types.UUID, autogenerate: true}
  @foreign_key_type Albuminum.Types.UUID
  schema "images" do
    field :filename, :string
    field :path, :string
    field :alt_text, :string
    field :caption, :string

    has_many :album_images, AlbumImage
    has_one :source, ImageSource
    many_to_many :tags, Tag, join_through: "image_tags"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(image, attrs) do
    image
    |> cast(attrs, [:filename, :path])
    |> validate_required([:filename, :path])
  end

  @doc """
  Changeset for updating image metadata (alt_text, caption).
  """
  def metadata_changeset(image, attrs) do
    image
    |> cast(attrs, [:alt_text, :caption])
    |> validate_length(:alt_text, max: 500)
    |> validate_length(:caption, max: 2000)
  end
end
