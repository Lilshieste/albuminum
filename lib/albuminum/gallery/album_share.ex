defmodule Albuminum.Gallery.AlbumShare do
  use Ecto.Schema
  import Ecto.Changeset

  alias Albuminum.Gallery.Album

  schema "album_shares" do
    field :token, :string

    belongs_to :album, Album

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(album_share, attrs) do
    album_share
    |> cast(attrs, [:token, :album_id])
    |> validate_required([:token, :album_id])
    |> unique_constraint(:token)
    |> unique_constraint(:album_id)
  end
end
