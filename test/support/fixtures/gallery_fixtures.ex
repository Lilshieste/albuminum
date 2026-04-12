defmodule Albuminum.GalleryFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Albuminum.Gallery` context.
  """

  @doc """
  Generate a album.
  """
  def album_fixture(attrs \\ %{}) do
    {:ok, album} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name"
      })
      |> Albuminum.Gallery.create_album()

    album
  end
end
