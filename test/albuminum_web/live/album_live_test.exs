defmodule AlbuminumWeb.AlbumLiveTest do
  use AlbuminumWeb.ConnCase

  import Phoenix.LiveViewTest
  import Albuminum.GalleryFixtures

  @create_attrs %{name: "some name", description: "some description"}
  @update_attrs %{name: "some updated name", description: "some updated description"}
  @invalid_attrs %{name: nil, description: nil}

  defp create_album(%{scope: scope}) do
    album = album_fixture(%{scope: scope})
    %{album: album}
  end

  describe "Index" do
    setup [:register_and_log_in_user, :create_album]

    test "lists all albums", %{conn: conn, album: album} do
      {:ok, _index_live, html} = live(conn, ~p"/albums")

      assert html =~ "Listing Albums"
      assert html =~ album.name
    end

    test "saves new album", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/albums")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Album")
               |> render_click()
               |> follow_redirect(conn, ~p"/albums/new")

      assert render(form_live) =~ "New Album"

      assert form_live
             |> form("#album-form", album: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#album-form", album: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/albums")

      html = render(index_live)
      assert html =~ "Album created successfully"
      assert html =~ "some name"
    end

    test "updates album in listing", %{conn: conn, album: album} do
      {:ok, index_live, _html} = live(conn, ~p"/albums")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#albums-#{album.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/albums/#{album}/edit")

      assert render(form_live) =~ "Edit Album"

      assert form_live
             |> form("#album-form", album: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#album-form", album: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/albums")

      html = render(index_live)
      assert html =~ "Album updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes album in listing", %{conn: conn, album: album} do
      {:ok, index_live, _html} = live(conn, ~p"/albums")

      assert index_live |> element("#albums-#{album.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#albums-#{album.id}")
    end
  end

  describe "Show" do
    setup [:register_and_log_in_user, :create_album]

    test "displays album", %{conn: conn, album: album} do
      {:ok, _show_live, html} = live(conn, ~p"/albums/#{album}")

      assert html =~ album.name
      assert html =~ "Images in Album"
    end

    test "groups available images by source", %{conn: conn, album: album} do
      # Create sample and Google Photos images
      _sample = image_fixture(%{filename: "sample.jpg"})
      _google = google_photos_image_fixture(%{filename: "from_google.jpg"})

      {:ok, _show_live, html} = live(conn, ~p"/albums/#{album}")

      assert html =~ "Sample Images"
      assert html =~ "Google Photos"
    end

    test "toggles image group collapse", %{conn: conn, album: album} do
      _sample = image_fixture(%{filename: "sample.jpg"})

      {:ok, show_live, html} = live(conn, ~p"/albums/#{album}")

      # Group should be expanded by default, showing the image
      assert html =~ "sample.jpg"
      assert html =~ "hero-chevron-down"

      # Click to collapse
      html = show_live |> element("button[phx-value-group='sample']") |> render_click()

      # Image should be hidden, chevron should point right
      refute html =~ "sample.jpg"
      assert html =~ "hero-chevron-right"

      # Click to expand again
      html = show_live |> element("button[phx-value-group='sample']") |> render_click()

      assert html =~ "sample.jpg"
      assert html =~ "hero-chevron-down"
    end

    test "updates album and returns to show", %{conn: conn, album: album} do
      {:ok, show_live, _html} = live(conn, ~p"/albums/#{album}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/albums/#{album}/edit?return_to=show")

      assert render(form_live) =~ "Edit Album"

      assert form_live
             |> form("#album-form", album: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#album-form", album: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/albums/#{album}")

      html = render(show_live)
      assert html =~ "Album updated successfully"
      assert html =~ "some updated name"
    end
  end

  describe "unauthenticated access" do
    test "redirects to login when not authenticated", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log-in"}}} = live(conn, ~p"/albums")
    end
  end

  describe "Google Photos picker auth" do
    setup do
      user = Albuminum.AccountsFixtures.google_photos_user_with_expired_token_fixture()
      scope = Albuminum.Accounts.Scope.for_user(user)
      album = album_fixture(%{scope: scope})
      conn = Phoenix.ConnTest.build_conn()
      %{conn: log_in_user(conn, user), user: user, scope: scope, album: album}
    end

    test "shows re-auth prompt when token refresh fails on page load", %{conn: conn, album: album} do
      {:ok, view, _html} = live(conn, ~p"/albums/#{album}")

      # Component should show "Connect Google Photos" button for re-auth,
      # NOT an error message with "Try Again"
      html = render(view)
      assert html =~ "Connect Google Photos"
      refute html =~ "Try Again"
      refute html =~ "Failed to"
    end

    test "re-auth link redirects to Google Photos OAuth with return path", %{conn: conn, album: album} do
      {:ok, view, _html} = live(conn, ~p"/albums/#{album}")

      # "Connect Google Photos" link should point to photos OAuth with return_to
      html = render(view)
      assert html =~ ~s(href="/auth/google/photos?return_to=)
      assert html =~ ~s(return_to=%2Falbums%2F#{album.id})
    end
  end
end
