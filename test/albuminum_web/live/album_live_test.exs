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

  describe "Album sharing" do
    setup [:register_and_log_in_user, :create_album]

    test "shows Share button when not sharing", %{conn: conn, album: album} do
      {:ok, _view, html} = live(conn, ~p"/albums/#{album}")

      assert html =~ "Share"
      refute html =~ "Share link:"
    end

    test "clicking Share creates share and shows link", %{conn: conn, album: album} do
      {:ok, view, _html} = live(conn, ~p"/albums/#{album}")

      html = view |> element("button", "Share") |> render_click()

      assert html =~ "Share link:"
      assert html =~ "/view/"
      assert html =~ "Stop Sharing"
    end

    test "clicking Stop Sharing removes share", %{conn: conn, album: album} do
      # Create share first
      Albuminum.Gallery.toggle_album_share(album)

      {:ok, view, html} = live(conn, ~p"/albums/#{album}")
      assert html =~ "Share link:"

      html = view |> element("button", "Stop Sharing") |> render_click()

      refute html =~ "Share link:"
      assert html =~ "Share"
    end
  end

  describe "Public album view" do
    setup [:register_and_log_in_user, :create_album]

    test "accessible via share token without auth", %{album: album} do
      {:ok, share} = Albuminum.Gallery.toggle_album_share(album)

      # Use fresh conn without auth
      conn = Phoenix.ConnTest.build_conn()
      {:ok, _view, html} = live(conn, ~p"/view/#{share.token}")

      assert html =~ album.name
    end

    test "shows album images", %{album: album} do
      image = image_fixture(%{filename: "test_image.jpg"})
      Albuminum.Gallery.add_image_to_album(album, image)
      {:ok, share} = Albuminum.Gallery.toggle_album_share(album)

      conn = Phoenix.ConnTest.build_conn()
      {:ok, _view, html} = live(conn, ~p"/view/#{share.token}")

      assert html =~ "test_image.jpg"
    end

    test "shows friendly error for invalid token" do
      conn = Phoenix.ConnTest.build_conn()

      {:ok, _view, html} = live(conn, ~p"/view/invalid_token")

      assert html =~ "Album Not Found"
      assert html =~ "no longer shared"
      assert html =~ "Go Home"
    end

    test "realtime revocation when owner stops sharing", %{album: album} do
      {:ok, share} = Albuminum.Gallery.toggle_album_share(album)
      conn = Phoenix.ConnTest.build_conn()

      # Viewer opens public view
      {:ok, view, html} = live(conn, ~p"/view/#{share.token}")
      assert html =~ album.name

      # Owner stops sharing (triggers broadcast)
      Albuminum.Gallery.toggle_album_share(album)

      # Viewer should see "not found" automatically
      html = render(view)
      assert html =~ "Album Not Found"
    end
  end

  describe "Image lightbox" do
    setup [:register_and_log_in_user, :create_album]

    test "clicking image opens lightbox", %{conn: conn, album: album} do
      image = image_fixture(%{filename: "lightbox_test.jpg"})
      Albuminum.Gallery.add_image_to_album(album, image)

      {:ok, view, _html} = live(conn, ~p"/albums/#{album}")

      # Click on image to open lightbox
      html =
        view
        |> element("img[alt='lightbox_test.jpg']")
        |> render_click()

      # Lightbox should be visible with full-size image
      assert html =~ "id=\"lightbox\""
      assert html =~ "max-h-[90vh]"
    end

    test "clicking lightbox closes it", %{conn: conn, album: album} do
      image = image_fixture(%{filename: "close_test.jpg"})
      Albuminum.Gallery.add_image_to_album(album, image)

      {:ok, view, _html} = live(conn, ~p"/albums/#{album}")

      # Open lightbox
      view |> element("img[alt='close_test.jpg']") |> render_click()

      # Close by clicking the overlay
      html = view |> element("#lightbox") |> render_click()

      refute html =~ "id=\"lightbox\""
    end

    test "lightbox works in public view", %{album: album} do
      image = image_fixture(%{filename: "public_lightbox.jpg"})
      Albuminum.Gallery.add_image_to_album(album, image)
      {:ok, share} = Albuminum.Gallery.toggle_album_share(album)

      conn = Phoenix.ConnTest.build_conn()
      {:ok, view, _html} = live(conn, ~p"/view/#{share.token}")

      # Click image to open lightbox
      html = view |> element("img[alt='public_lightbox.jpg']") |> render_click()

      assert html =~ "id=\"lightbox\""
      assert html =~ "max-h-[90vh]"
    end
  end

  describe "Public view layout" do
    setup [:register_and_log_in_user, :create_album]

    test "hides user menu in public view", %{album: album} do
      {:ok, share} = Albuminum.Gallery.toggle_album_share(album)

      conn = Phoenix.ConnTest.build_conn()
      {:ok, _view, html} = live(conn, ~p"/view/#{share.token}")

      # Should NOT show user menu items
      refute html =~ "Settings"
      refute html =~ "Log out"
      refute html =~ "Log in"
      refute html =~ "Register"
    end

    test "shows minimal footer with branding and theme toggle", %{album: album} do
      {:ok, share} = Albuminum.Gallery.toggle_album_share(album)

      conn = Phoenix.ConnTest.build_conn()
      {:ok, _view, html} = live(conn, ~p"/view/#{share.token}")

      # Footer should have Albuminum link and theme toggle
      assert html =~ ~s(href="/")
      assert html =~ "Albuminum"
      assert html =~ "phx:set-theme"
    end

    test "does not show navbar header", %{album: album} do
      {:ok, share} = Albuminum.Gallery.toggle_album_share(album)

      conn = Phoenix.ConnTest.build_conn()
      {:ok, _view, html} = live(conn, ~p"/view/#{share.token}")

      # Should NOT have navbar elements
      refute html =~ "GitHub"
      refute html =~ ~s(class="navbar)
    end

    test "shows user menu in regular album view", %{conn: conn, album: album} do
      {:ok, _view, html} = live(conn, ~p"/albums/#{album}")

      # Regular view SHOULD show user menu
      assert html =~ "Settings"
      assert html =~ "Log out"
    end
  end
end
