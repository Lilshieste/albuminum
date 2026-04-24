defmodule AlbuminumWeb.TagsLiveTest do
  use AlbuminumWeb.ConnCase

  import Phoenix.LiveViewTest
  import Albuminum.GalleryFixtures

  alias Albuminum.Gallery

  describe "Index" do
    setup [:register_and_log_in_user]

    test "lists all user's tags", %{conn: conn, scope: scope} do
      {:ok, tag1} = Gallery.create_tag(scope, %{name: "vacation"})
      {:ok, tag2} = Gallery.create_tag(scope, %{name: "family"})

      {:ok, _view, html} = live(conn, ~p"/tags")

      assert html =~ "Tags"
      assert html =~ tag1.name
      assert html =~ tag2.name
    end

    test "shows image count for each tag", %{conn: conn, scope: scope} do
      {:ok, tag} = Gallery.create_tag(scope, %{name: "nature"})
      image1 = image_fixture(%{filename: "forest.jpg"})
      image2 = image_fixture(%{filename: "mountain.jpg"})
      Gallery.add_tag_to_image(image1, tag)
      Gallery.add_tag_to_image(image2, tag)

      {:ok, _view, html} = live(conn, ~p"/tags")

      # Should show count of 2 images
      assert html =~ "2 images"
    end

    test "shows empty state when no tags", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/tags")

      assert html =~ "No tags yet"
    end

    test "clicking tag navigates to tag show page", %{conn: conn, scope: scope} do
      {:ok, tag} = Gallery.create_tag(scope, %{name: "travel"})

      {:ok, view, _html} = live(conn, ~p"/tags")

      view
      |> element("a", tag.name)
      |> render_click()

      assert_redirect(view, ~p"/tags/#{tag}")
    end

    test "delete button removes tag", %{conn: conn, scope: scope} do
      {:ok, tag} = Gallery.create_tag(scope, %{name: "deletable"})

      {:ok, view, _html} = live(conn, ~p"/tags")

      view
      |> element("[phx-click='delete_tag'][phx-value-id='#{tag.id}']")
      |> render_click()

      refute has_element?(view, "a", "deletable")
    end
  end

  describe "Show" do
    setup [:register_and_log_in_user]

    test "displays tag name and images", %{conn: conn, scope: scope} do
      {:ok, tag} = Gallery.create_tag(scope, %{name: "portraits"})
      image = image_fixture(%{filename: "headshot.jpg"})
      Gallery.add_tag_to_image(image, tag)

      {:ok, _view, html} = live(conn, ~p"/tags/#{tag}")

      assert html =~ "portraits"
      assert html =~ "headshot.jpg"
    end

    test "shows empty state when tag has no images", %{conn: conn, scope: scope} do
      {:ok, tag} = Gallery.create_tag(scope, %{name: "empty"})

      {:ok, _view, html} = live(conn, ~p"/tags/#{tag}")

      assert html =~ "No images with this tag"
    end

    test "back button returns to tags index", %{conn: conn, scope: scope} do
      {:ok, tag} = Gallery.create_tag(scope, %{name: "test"})

      {:ok, view, _html} = live(conn, ~p"/tags/#{tag}")

      view
      |> element("a", "Back")
      |> render_click()

      assert_redirect(view, ~p"/tags")
    end
  end
end
