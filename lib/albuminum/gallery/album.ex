defmodule Albuminum.Gallery.Album do
  use Ecto.Schema
  import Ecto.Changeset

  alias Albuminum.Accounts.User
  alias Albuminum.Gallery.{AlbumImage, Image}

  @primary_key {:id, Albuminum.Types.UUID, autogenerate: true}
  @foreign_key_type Albuminum.Types.UUID
  schema "albums" do
    field :name, :string
    field :description, :string

    belongs_to :user, User

    has_many :album_images, AlbumImage, preload_order: [asc: :position]
    many_to_many :images, Image, join_through: AlbumImage

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(album, attrs) do
    album
    |> cast(attrs, [:name, :description, :user_id])
    |> validate_required([:name, :user_id])
  end
end
