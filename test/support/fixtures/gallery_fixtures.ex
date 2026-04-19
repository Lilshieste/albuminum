defmodule Albuminum.GalleryFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Albuminum.Gallery` context.
  """

  import Albuminum.AccountsFixtures

  @doc """
  Generate an album for a user.
  Accepts optional scope, creates one if not provided.
  """
  def album_fixture(attrs \\ %{})

  def album_fixture(%{scope: scope} = attrs) do
    {:ok, album} =
      attrs
      |> Map.delete(:scope)
      |> Enum.into(%{
        description: "some description",
        name: "some name"
      })
      |> then(&Albuminum.Gallery.create_album(scope, &1))

    album
  end

  def album_fixture(attrs) do
    scope = user_scope_fixture()
    album_fixture(Map.put(attrs, :scope, scope))
  end

  @doc """
  Generate an image without a source (sample image).
  """
  def image_fixture(attrs \\ %{}) do
    {:ok, image} =
      attrs
      |> Enum.into(%{
        filename: "sample_#{System.unique_integer([:positive])}.jpg",
        path: "https://picsum.photos/seed/test/400/300"
      })
      |> Albuminum.Gallery.create_image()

    image
  end

  @doc """
  Generate an image with a Google Photos source.
  """
  def google_photos_image_fixture(attrs \\ %{}) do
    external_id = "google_#{System.unique_integer([:positive])}"

    image_attrs =
      attrs
      |> Enum.into(%{
        filename: "IMG_#{System.unique_integer([:positive])}.jpg",
        path: "/uploads/#{external_id}.jpg"
      })

    {:ok, image} =
      Albuminum.Gallery.create_image_with_source("google_photos", external_id, image_attrs)

    Albuminum.Repo.preload(image, :source)
  end
end
