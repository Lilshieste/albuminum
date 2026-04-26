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

    test "toggle_album_share/1 creates share when none exists" do
      album = album_fixture()

      assert {:ok, %AlbumShare{is_active: true} = share} = Gallery.toggle_album_share(album)
      assert share.album_id == album.id
      assert is_binary(share.token)
      assert String.length(share.token) > 10
    end

    test "toggle_album_share/1 deactivates share when active" do
      album = album_fixture()
      {:ok, share1} = Gallery.toggle_album_share(album)

      assert {:ok, %AlbumShare{is_active: false}} = Gallery.toggle_album_share(album)
      assert Gallery.get_album_share(album) == nil

      # Token stays the same
      {:ok, share2} = Gallery.toggle_album_share(album)
      assert share2.token == share1.token
    end

    test "toggle_album_share/1 preserves token across toggles" do
      album = album_fixture()

      {:ok, share1} = Gallery.toggle_album_share(album)
      token = share1.token

      # Toggle off
      Gallery.toggle_album_share(album)
      # Toggle on
      {:ok, share2} = Gallery.toggle_album_share(album)

      assert share2.token == token
    end

    test "get_album_share/1 returns active share for album" do
      album = album_fixture()
      {:ok, share} = Gallery.toggle_album_share(album)

      assert Gallery.get_album_share(album) == share
    end

    test "get_album_share/1 returns nil when no share exists" do
      album = album_fixture()

      assert Gallery.get_album_share(album) == nil
    end

    test "get_album_share/1 returns nil when share is inactive" do
      album = album_fixture()
      Gallery.toggle_album_share(album)
      Gallery.toggle_album_share(album)  # Deactivate

      assert Gallery.get_album_share(album) == nil
    end

    test "get_album_by_share_token!/1 returns album for valid token" do
      album = album_fixture()
      {:ok, share} = Gallery.toggle_album_share(album)

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
      {:ok, share} = Gallery.toggle_album_share(album)

      found = Gallery.get_album_with_images_by_share_token!(share.token)
      assert found.id == album.id
      assert length(found.album_images) == 1
    end

    test "share is deleted when album is deleted" do
      scope = user_scope_fixture()
      album = album_fixture(%{scope: scope})
      {:ok, share} = Gallery.toggle_album_share(album)
      token = share.token

      Gallery.delete_album(album)

      assert_raise Ecto.NoResultsError, fn ->
        Gallery.get_album_by_share_token!(token)
      end
    end
  end

  # ===========================================================================
  # Step 1: Schema Tests (TDD - tests written before implementation)
  # ===========================================================================

  describe "Tag schema" do
    alias Albuminum.Gallery.Tag
    import Albuminum.AccountsFixtures

    test "valid changeset with name and user_id" do
      user = user_fixture()
      changeset = Tag.changeset(%Tag{}, %{name: "vacation", user_id: user.id})

      assert changeset.valid?
    end

    test "invalid changeset without name" do
      user = user_fixture()
      changeset = Tag.changeset(%Tag{}, %{user_id: user.id})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
    end

    test "invalid changeset without user_id" do
      changeset = Tag.changeset(%Tag{}, %{name: "vacation"})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).user_id
    end

    test "name must be between 1 and 50 characters" do
      user = user_fixture()

      # Empty name
      changeset = Tag.changeset(%Tag{}, %{name: "", user_id: user.id})
      refute changeset.valid?

      # Too long (51 chars)
      long_name = String.duplicate("a", 51)
      changeset = Tag.changeset(%Tag{}, %{name: long_name, user_id: user.id})
      refute changeset.valid?

      # Max valid (50 chars)
      max_name = String.duplicate("a", 50)
      changeset = Tag.changeset(%Tag{}, %{name: max_name, user_id: user.id})
      assert changeset.valid?
    end
  end

  describe "ImageTag schema" do
    alias Albuminum.Gallery.ImageTag
    import Albuminum.GalleryFixtures
    import Albuminum.AccountsFixtures

    test "valid changeset with image_id and tag_id" do
      uuid1 = Ecto.UUID.generate()
      uuid2 = Ecto.UUID.generate()
      changeset = ImageTag.changeset(%ImageTag{}, %{image_id: uuid1, tag_id: uuid2})

      assert changeset.valid?
    end

    test "invalid changeset without image_id" do
      changeset = ImageTag.changeset(%ImageTag{}, %{tag_id: Ecto.UUID.generate()})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).image_id
    end

    test "invalid changeset without tag_id" do
      changeset = ImageTag.changeset(%ImageTag{}, %{image_id: Ecto.UUID.generate()})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).tag_id
    end
  end

  describe "Image metadata changeset" do
    alias Albuminum.Gallery.Image
    import Albuminum.GalleryFixtures

    test "valid metadata changeset with alt_text and caption" do
      image = image_fixture()
      changeset = Image.metadata_changeset(image, %{
        alt_text: "A sunset over the ocean",
        caption: "Taken during our trip to Hawaii"
      })

      assert changeset.valid?
    end

    test "alt_text max length is 500 characters" do
      image = image_fixture()

      # Too long (501 chars)
      long_alt = String.duplicate("a", 501)
      changeset = Image.metadata_changeset(image, %{alt_text: long_alt})
      refute changeset.valid?
      assert "should be at most 500 character(s)" in errors_on(changeset).alt_text

      # Max valid (500 chars)
      max_alt = String.duplicate("a", 500)
      changeset = Image.metadata_changeset(image, %{alt_text: max_alt})
      assert changeset.valid?
    end

    test "caption max length is 2000 characters" do
      image = image_fixture()

      # Too long (2001 chars)
      long_caption = String.duplicate("a", 2001)
      changeset = Image.metadata_changeset(image, %{caption: long_caption})
      refute changeset.valid?
      assert "should be at most 2000 character(s)" in errors_on(changeset).caption

      # Max valid (2000 chars)
      max_caption = String.duplicate("a", 2000)
      changeset = Image.metadata_changeset(image, %{caption: max_caption})
      assert changeset.valid?
    end

    test "allows nil values for alt_text and caption" do
      image = image_fixture()
      changeset = Image.metadata_changeset(image, %{alt_text: nil, caption: nil})

      assert changeset.valid?
    end
  end

  # ===========================================================================
  # Step 2: Gallery Context Tests (TDD - tests written before implementation)
  # ===========================================================================

  describe "tags context" do
    import Albuminum.GalleryFixtures
    import Albuminum.AccountsFixtures

    test "list_tags/1 returns all tags for user" do
      scope = user_scope_fixture()
      {:ok, _tag1} = Gallery.create_tag(scope, %{name: "vacation"})
      {:ok, _tag2} = Gallery.create_tag(scope, %{name: "family"})

      tags = Gallery.list_tags(scope)
      assert length(tags) == 2
      assert Enum.map(tags, & &1.name) |> Enum.sort() == ["family", "vacation"]
    end

    test "list_tags/1 does not return other users' tags" do
      scope1 = user_scope_fixture()
      scope2 = user_scope_fixture()

      {:ok, _} = Gallery.create_tag(scope1, %{name: "user1_tag"})
      {:ok, tag2} = Gallery.create_tag(scope2, %{name: "user2_tag"})

      tags = Gallery.list_tags(scope2)
      assert tags == [tag2]
    end

    test "get_tag!/2 returns tag by id for user" do
      scope = user_scope_fixture()
      {:ok, tag} = Gallery.create_tag(scope, %{name: "vacation"})

      assert Gallery.get_tag!(scope, tag.id) == tag
    end

    test "get_tag!/2 raises for other users' tags" do
      scope1 = user_scope_fixture()
      scope2 = user_scope_fixture()
      {:ok, tag} = Gallery.create_tag(scope1, %{name: "private"})

      assert_raise Ecto.NoResultsError, fn ->
        Gallery.get_tag!(scope2, tag.id)
      end
    end

    test "create_tag/2 creates tag for user" do
      scope = user_scope_fixture()

      assert {:ok, tag} = Gallery.create_tag(scope, %{name: "vacation"})
      assert tag.name == "vacation"
      assert tag.user_id == scope.user.id
    end

    test "create_tag/2 fails for duplicate name per user" do
      scope = user_scope_fixture()
      {:ok, _} = Gallery.create_tag(scope, %{name: "vacation"})

      assert {:error, changeset} = Gallery.create_tag(scope, %{name: "vacation"})
      assert "tag already exists" in errors_on(changeset).user_id
    end

    test "create_tag/2 allows same name for different users" do
      scope1 = user_scope_fixture()
      scope2 = user_scope_fixture()

      assert {:ok, _} = Gallery.create_tag(scope1, %{name: "vacation"})
      assert {:ok, _} = Gallery.create_tag(scope2, %{name: "vacation"})
    end

    test "find_or_create_tag/2 returns existing tag" do
      scope = user_scope_fixture()
      {:ok, existing} = Gallery.create_tag(scope, %{name: "vacation"})

      assert {:ok, found} = Gallery.find_or_create_tag(scope, "vacation")
      assert found.id == existing.id
    end

    test "find_or_create_tag/2 creates tag if not exists" do
      scope = user_scope_fixture()

      assert {:ok, tag} = Gallery.find_or_create_tag(scope, "new_tag")
      assert tag.name == "new_tag"
    end

    test "find_or_create_tag/2 trims whitespace" do
      scope = user_scope_fixture()

      assert {:ok, tag} = Gallery.find_or_create_tag(scope, "  spaced  ")
      assert tag.name == "spaced"
    end

    test "delete_tag/1 deletes tag" do
      scope = user_scope_fixture()
      {:ok, tag} = Gallery.create_tag(scope, %{name: "temp"})

      assert {:ok, _} = Gallery.delete_tag(tag)
      assert_raise Ecto.NoResultsError, fn -> Gallery.get_tag!(scope, tag.id) end
    end
  end

  describe "image tags context" do
    import Albuminum.GalleryFixtures
    import Albuminum.AccountsFixtures

    test "add_tag_to_image/2 adds tag to image" do
      scope = user_scope_fixture()
      image = image_fixture()
      {:ok, tag} = Gallery.create_tag(scope, %{name: "vacation"})

      assert {:ok, _} = Gallery.add_tag_to_image(image, tag)
      tags = Gallery.list_tags_for_image(image)
      assert length(tags) == 1
      assert hd(tags).name == "vacation"
    end

    test "add_tag_to_image/2 is idempotent" do
      scope = user_scope_fixture()
      image = image_fixture()
      {:ok, tag} = Gallery.create_tag(scope, %{name: "vacation"})

      assert {:ok, _} = Gallery.add_tag_to_image(image, tag)
      assert {:ok, _} = Gallery.add_tag_to_image(image, tag)

      tags = Gallery.list_tags_for_image(image)
      assert length(tags) == 1
    end

    test "add_tag_to_image/2 enforces 100 tag limit" do
      scope = user_scope_fixture()
      image = image_fixture()

      # Add 100 tags
      for i <- 1..100 do
        {:ok, tag} = Gallery.create_tag(scope, %{name: "tag_#{i}"})
        {:ok, _} = Gallery.add_tag_to_image(image, tag)
      end

      # 101st should fail
      {:ok, tag101} = Gallery.create_tag(scope, %{name: "tag_101"})
      assert {:error, :tag_limit_reached} = Gallery.add_tag_to_image(image, tag101)
    end

    test "remove_tag_from_image/2 removes tag from image" do
      scope = user_scope_fixture()
      image = image_fixture()
      {:ok, tag} = Gallery.create_tag(scope, %{name: "vacation"})

      Gallery.add_tag_to_image(image, tag)
      assert :ok = Gallery.remove_tag_from_image(image, tag)

      tags = Gallery.list_tags_for_image(image)
      assert tags == []
    end

    test "list_tags_for_image/1 returns all tags for image" do
      scope = user_scope_fixture()
      image = image_fixture()
      {:ok, tag1} = Gallery.create_tag(scope, %{name: "vacation"})
      {:ok, tag2} = Gallery.create_tag(scope, %{name: "family"})

      Gallery.add_tag_to_image(image, tag1)
      Gallery.add_tag_to_image(image, tag2)

      tags = Gallery.list_tags_for_image(image)
      assert length(tags) == 2
    end
  end

  describe "image metadata context" do
    import Albuminum.GalleryFixtures

    test "update_image_metadata/2 updates alt_text and caption" do
      image = image_fixture()

      assert {:ok, updated} = Gallery.update_image_metadata(image, %{
        alt_text: "A beautiful sunset",
        caption: "Taken in Hawaii"
      })

      assert updated.alt_text == "A beautiful sunset"
      assert updated.caption == "Taken in Hawaii"
    end

    test "update_image_metadata/2 allows partial updates" do
      image = image_fixture()

      assert {:ok, updated} = Gallery.update_image_metadata(image, %{alt_text: "Just alt"})
      assert updated.alt_text == "Just alt"
      assert updated.caption == nil
    end
  end

  describe "image filtering by tags" do
    import Albuminum.GalleryFixtures
    import Albuminum.AccountsFixtures

    test "list_images_not_in_album_filtered/2 with empty tags returns all available" do
      scope = user_scope_fixture()
      album = album_fixture(%{scope: scope})
      image1 = image_fixture(%{filename: "img1.jpg"})
      _image2 = image_fixture(%{filename: "img2.jpg"})

      # Add image1 to album
      Gallery.add_image_to_album(album, image1)

      # Filter with empty tags should return image2 (not in album)
      images = Gallery.list_images_not_in_album_filtered(album, [])
      assert length(images) == 1
      assert hd(images).filename == "img2.jpg"
    end

    test "list_images_not_in_album_filtered/2 filters by tags (OR logic)" do
      scope = user_scope_fixture()
      album = album_fixture(%{scope: scope})
      image1 = image_fixture(%{filename: "vacation.jpg"})
      image2 = image_fixture(%{filename: "family.jpg"})
      _image3 = image_fixture(%{filename: "work.jpg"})

      {:ok, vacation_tag} = Gallery.create_tag(scope, %{name: "vacation"})
      {:ok, family_tag} = Gallery.create_tag(scope, %{name: "family"})

      Gallery.add_tag_to_image(image1, vacation_tag)
      Gallery.add_tag_to_image(image2, family_tag)
      # image3 has no tags

      # Filter by vacation tag
      images = Gallery.list_images_not_in_album_filtered(album, [vacation_tag.id])
      assert length(images) == 1
      assert hd(images).filename == "vacation.jpg"

      # Filter by both tags (OR logic)
      images = Gallery.list_images_not_in_album_filtered(album, [vacation_tag.id, family_tag.id])
      assert length(images) == 2
    end

    test "list_images_not_in_album_filtered/2 excludes images already in album" do
      scope = user_scope_fixture()
      album = album_fixture(%{scope: scope})
      image1 = image_fixture(%{filename: "in_album.jpg"})
      image2 = image_fixture(%{filename: "not_in_album.jpg"})

      {:ok, tag} = Gallery.create_tag(scope, %{name: "shared_tag"})
      Gallery.add_tag_to_image(image1, tag)
      Gallery.add_tag_to_image(image2, tag)

      # Add image1 to album
      Gallery.add_image_to_album(album, image1)

      # Should only return image2
      images = Gallery.list_images_not_in_album_filtered(album, [tag.id])
      assert length(images) == 1
      assert hd(images).filename == "not_in_album.jpg"
    end
  end
end
