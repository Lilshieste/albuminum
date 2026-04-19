defmodule Albuminum.GalleryTest do
  use Albuminum.DataCase

  alias Albuminum.Gallery

  describe "albums" do
    alias Albuminum.Gallery.Album

    import Albuminum.GalleryFixtures
    import Albuminum.AccountsFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_albums/1 returns all albums for user" do
      scope = user_scope_fixture()
      album = album_fixture(%{scope: scope})
      assert Gallery.list_albums(scope) == [album]
    end

    test "list_albums/1 does not return other users' albums" do
      scope1 = user_scope_fixture()
      scope2 = user_scope_fixture()

      _album1 = album_fixture(%{scope: scope1, name: "User 1 Album"})
      album2 = album_fixture(%{scope: scope2, name: "User 2 Album"})

      assert Gallery.list_albums(scope2) == [album2]
    end

    test "get_album!/2 returns the album with given id" do
      scope = user_scope_fixture()
      album = album_fixture(%{scope: scope})
      assert Gallery.get_album!(scope, album.id) == album
    end

    test "get_album!/2 raises for other users' albums" do
      scope1 = user_scope_fixture()
      scope2 = user_scope_fixture()
      album = album_fixture(%{scope: scope1})

      assert_raise Ecto.NoResultsError, fn ->
        Gallery.get_album!(scope2, album.id)
      end
    end

    test "create_album/2 with valid data creates an album" do
      scope = user_scope_fixture()
      valid_attrs = %{name: "some name", description: "some description"}

      assert {:ok, %Album{} = album} = Gallery.create_album(scope, valid_attrs)
      assert album.name == "some name"
      assert album.description == "some description"
      assert album.user_id == scope.user.id
    end

    test "create_album/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Gallery.create_album(scope, @invalid_attrs)
    end

    test "update_album/2 with valid data updates the album" do
      album = album_fixture()
      update_attrs = %{name: "some updated name", description: "some updated description"}

      assert {:ok, %Album{} = album} = Gallery.update_album(album, update_attrs)
      assert album.name == "some updated name"
      assert album.description == "some updated description"
    end

    test "update_album/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      album = album_fixture(%{scope: scope})
      assert {:error, %Ecto.Changeset{}} = Gallery.update_album(album, @invalid_attrs)
      assert album == Gallery.get_album!(scope, album.id)
    end

    test "delete_album/1 deletes the album" do
      scope = user_scope_fixture()
      album = album_fixture(%{scope: scope})
      assert {:ok, %Album{}} = Gallery.delete_album(album)
      assert_raise Ecto.NoResultsError, fn -> Gallery.get_album!(scope, album.id) end
    end

    test "change_album/1 returns an album changeset" do
      album = album_fixture()
      assert %Ecto.Changeset{} = Gallery.change_album(album)
    end
  end

  describe "import_google_photo_to_album/3" do
    import Albuminum.GalleryFixtures
    import Albuminum.AccountsFixtures

    test "returns error when baseUrl is nil" do
      scope = user_scope_fixture()
      album = album_fixture(%{scope: scope})

      media_item = %{
        "id" => "some_google_id",
        "baseUrl" => nil,
        "filename" => "test.jpg",
        "mimeType" => "image/jpeg"
      }

      assert {:error, :missing_base_url} = Gallery.import_google_photo_to_album(album, media_item, "fake_token")
    end

    test "returns error when baseUrl is empty string" do
      scope = user_scope_fixture()
      album = album_fixture(%{scope: scope})

      media_item = %{
        "id" => "some_google_id",
        "baseUrl" => "",
        "filename" => "test.jpg",
        "mimeType" => "image/jpeg"
      }

      assert {:error, :missing_base_url} = Gallery.import_google_photo_to_album(album, media_item, "fake_token")
    end
  end
end
