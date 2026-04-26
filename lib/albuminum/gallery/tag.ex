defmodule Albuminum.Gallery.Tag do
  @moduledoc """
  Schema for user-defined tags.
  Tags are user-scoped and can be applied to images.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Albuminum.Accounts.User
  alias Albuminum.Gallery.Image

  @primary_key {:id, Albuminum.Types.UUID, autogenerate: true}
  @foreign_key_type Albuminum.Types.UUID
  schema "tags" do
    field :name, :string

    belongs_to :user, User
    many_to_many :images, Image, join_through: "image_tags"

    timestamps(type: :utc_datetime)
  end

  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name, :user_id])
    |> validate_required([:name, :user_id])
    |> validate_length(:name, min: 1, max: 50)
    |> unique_constraint([:user_id, :name], message: "tag already exists")
  end
end
