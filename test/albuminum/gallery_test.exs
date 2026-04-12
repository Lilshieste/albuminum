defmodule Albuminum.GalleryTest do
  use Albuminum.DataCase

  alias Albuminum.Gallery

  describe "albums" do
    alias Albuminum.Gallery.Album

    import Albuminum.GalleryFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_albums/0 returns all albums" do
      album = album_fixture()
      assert Gallery.list_albums() == [album]
    end

    test "get_album!/1 returns the album with given id" do
      album = album_fixture()
      assert Gallery.get_album!(album.id) == album
    end

    test "create_album/1 with valid data creates a album" do
      valid_attrs = %{name: "some name", description: "some description"}

      assert {:ok, %Album{} = album} = Gallery.create_album(valid_attrs)
      assert album.name == "some name"
      assert album.description == "some description"
    end

    test "create_album/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Gallery.create_album(@invalid_attrs)
    end

    test "update_album/2 with valid data updates the album" do
      album = album_fixture()
      update_attrs = %{name: "some updated name", description: "some updated description"}

      assert {:ok, %Album{} = album} = Gallery.update_album(album, update_attrs)
      assert album.name == "some updated name"
      assert album.description == "some updated description"
    end

    test "update_album/2 with invalid data returns error changeset" do
      album = album_fixture()
      assert {:error, %Ecto.Changeset{}} = Gallery.update_album(album, @invalid_attrs)
      assert album == Gallery.get_album!(album.id)
    end

    test "delete_album/1 deletes the album" do
      album = album_fixture()
      assert {:ok, %Album{}} = Gallery.delete_album(album)
      assert_raise Ecto.NoResultsError, fn -> Gallery.get_album!(album.id) end
    end

    test "change_album/1 returns a album changeset" do
      album = album_fixture()
      assert %Ecto.Changeset{} = Gallery.change_album(album)
    end
  end
end
