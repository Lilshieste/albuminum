defmodule Albuminum.Gallery.AlbumShare do
  use Ecto.Schema
  import Ecto.Changeset

  alias Albuminum.Gallery.Album

  @primary_key {:id, Albuminum.Types.UUID, autogenerate: true}
  @foreign_key_type Albuminum.Types.UUID
  schema "album_shares" do
    field :token, :string
    field :is_active, :boolean, default: true

    belongs_to :album, Album

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(album_share, attrs) do
    album_share
    |> cast(attrs, [:token, :album_id, :is_active])
    |> validate_required([:token, :album_id])
    |> unique_constraint(:token)
    |> unique_constraint(:album_id)
  end
end
