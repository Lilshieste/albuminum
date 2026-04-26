defmodule Albuminum.Gallery.ImageSource do
  @moduledoc """
  Stores external provider references for images.
  Supports multiple providers (Google Photos, iCloud, OneDrive, etc.)
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Albuminum.Gallery.Image

  @providers ~w(google_photos icloud onedrive)

  @primary_key {:id, Albuminum.Types.UUID, autogenerate: true}
  @foreign_key_type Albuminum.Types.UUID
  schema "image_sources" do
    field :provider, :string
    field :external_id, :string
    field :metadata, :map, default: %{}

    belongs_to :image, Image

    timestamps(type: :utc_datetime)
  end

  def changeset(image_source, attrs) do
    image_source
    |> cast(attrs, [:provider, :external_id, :metadata, :image_id])
    |> validate_required([:provider, :external_id, :image_id])
    |> validate_inclusion(:provider, @providers)
    |> unique_constraint([:provider, :external_id])
  end

  @doc """
  Builds image URL from source metadata.
  Each provider has different URL construction logic.
  """
  def build_url(source, opts \\ [])

  def build_url(%__MODULE__{provider: "google_photos", metadata: metadata}, opts) do
    base_url = metadata["base_url"]
    width = Keyword.get(opts, :width, 400)
    height = Keyword.get(opts, :height, 400)

    "#{base_url}=w#{width}-h#{height}"
  end

  def build_url(%__MODULE__{provider: _other, metadata: metadata}, _opts) do
    # Fallback for other providers - just use stored URL
    metadata["url"]
  end
end
