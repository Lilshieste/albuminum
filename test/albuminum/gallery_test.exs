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

  describe "group_images_by_source/1" do
    import Albuminum.GalleryFixtures

    test "groups images by provider" do
      sample1 = image_fixture(%{filename: "sample1.jpg"})
      sample2 = image_fixture(%{filename: "sample2.jpg"})
      google1 = google_photos_image_fixture(%{filename: "google1.jpg"})
      google2 = google_photos_image_fixture(%{filename: "google2.jpg"})

      # Preload source for sample images (will be nil)
      sample1 = Albuminum.Repo.preload(sample1, :source)
      sample2 = Albuminum.Repo.preload(sample2, :source)

      images = [sample1, google1, sample2, google2]
      grouped = Gallery.group_images_by_source(images)

      assert length(grouped) == 2

      # Google Photos should come first (sort order 0)
      {label1, key1, imgs1} = Enum.at(grouped, 0)
      assert label1 == "Google Photos"
      assert key1 == "google_photos"
      assert length(imgs1) == 2

      # Sample Images should come last (sort order 99)
      {label2, key2, imgs2} = Enum.at(grouped, 1)
      assert label2 == "Sample Images"
      assert key2 == "sample"
      assert length(imgs2) == 2
    end

    test "returns empty list for empty input" do
      assert Gallery.group_images_by_source([]) == []
    end

    test "handles images with only one source type" do
      sample = image_fixture() |> Albuminum.Repo.preload(:source)

      grouped = Gallery.group_images_by_source([sample])

      assert [{label, key, imgs}] = grouped
      assert label == "Sample Images"
      assert key == "sample"
      assert length(imgs) == 1
    end
  end

  describe "album sharing" do
    import Albuminum.GalleryFixtures
    import Albuminum.AccountsFixtures

    alias Albuminum.Gallery.AlbumShare

    test "create_album_share/1 creates a share with unique token" do
      album = album_fixture()

      assert {:ok, %AlbumShare{} = share} = Gallery.create_album_share(album)
      assert share.album_id == album.id
      assert is_binary(share.token)
      assert String.length(share.token) > 10
    end

    test "create_album_share/1 fails for duplicate album" do
      album = album_fixture()

      assert {:ok, _share1} = Gallery.create_album_share(album)
      assert {:error, _changeset} = Gallery.create_album_share(album)
    end

    test "get_album_share/1 returns share for album" do
      album = album_fixture()
      {:ok, share} = Gallery.create_album_share(album)

      assert Gallery.get_album_share(album) == share
    end

    test "get_album_share/1 returns nil when no share exists" do
      album = album_fixture()

      assert Gallery.get_album_share(album) == nil
    end

    test "delete_album_share/1 removes the share" do
      album = album_fixture()
      {:ok, _share} = Gallery.create_album_share(album)

      assert {:ok, _} = Gallery.delete_album_share(album)
      assert Gallery.get_album_share(album) == nil
    end

    test "toggle_album_share/1 creates share when none exists" do
      album = album_fixture()

      assert {:ok, %AlbumShare{}} = Gallery.toggle_album_share(album)
      assert Gallery.get_album_share(album) != nil
    end

    test "toggle_album_share/1 deletes share when one exists" do
      album = album_fixture()
      {:ok, _share} = Gallery.create_album_share(album)

      # Returns the deleted share record
      assert {:ok, %AlbumShare{}} = Gallery.toggle_album_share(album)
      assert Gallery.get_album_share(album) == nil
    end

    test "get_album_by_share_token!/1 returns album for valid token" do
      album = album_fixture()
      {:ok, share} = Gallery.create_album_share(album)

      found = Gallery.get_album_by_share_token!(share.token)
      assert found.id == album.id
    end

    test "get_album_by_share_token!/1 raises for invalid token" do
      assert_raise Ecto.NoResultsError, fn ->
        Gallery.get_album_by_share_token!("invalid_token")
      end
    end

    test "get_album_with_images_by_share_token!/1 preloads images" do
      scope = user_scope_fixture()
      album = album_fixture(%{scope: scope})
      image = image_fixture()
      Gallery.add_image_to_album(album, image)
      {:ok, share} = Gallery.create_album_share(album)

      found = Gallery.get_album_with_images_by_share_token!(share.token)
      assert found.id == album.id
      assert length(found.album_images) == 1
    end

    test "share is deleted when album is deleted" do
      scope = user_scope_fixture()
      album = album_fixture(%{scope: scope})
      {:ok, share} = Gallery.create_album_share(album)
      token = share.token

      Gallery.delete_album(album)

      assert_raise Ecto.NoResultsError, fn ->
        Gallery.get_album_by_share_token!(token)
      end
    end
  end
end
