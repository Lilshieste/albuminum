defmodule Albuminum.Gallery.ImageTag do
  @moduledoc """
  Join schema for image-tag associations.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Albuminum.Gallery.{Image, Tag}

  @primary_key false
  schema "image_tags" do
    belongs_to :image, Image, primary_key: true
    belongs_to :tag, Tag, primary_key: true

    timestamps(type: :utc_datetime)
  end

  def changeset(image_tag, attrs) do
    image_tag
    |> cast(attrs, [:image_id, :tag_id])
    |> validate_required([:image_id, :tag_id])
    |> foreign_key_constraint(:image_id)
    |> foreign_key_constraint(:tag_id)
    |> unique_constraint([:image_id, :tag_id])
  end
end
