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
end
