defmodule AlbuminumWeb.GoogleAuthControllerTest do
  use AlbuminumWeb.ConnCase

  describe "GET /auth/google" do
    test "redirects to Google OAuth", %{conn: conn} do
      conn = get(conn, ~p"/auth/google")

      assert redirected_to(conn) =~ "accounts.google.com"
      assert redirected_to(conn) =~ "client_id="
      assert redirected_to(conn) =~ "redirect_uri="
      assert redirected_to(conn) =~ "scope="
    end
  end

  describe "GET /auth/google/callback" do
    test "handles error response", %{conn: conn} do
      conn = get(conn, ~p"/auth/google/callback", %{"error" => "access_denied"})

      assert redirected_to(conn) == ~p"/users/log-in"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "access_denied"
    end

    test "handles error with description", %{conn: conn} do
      conn =
        get(conn, ~p"/auth/google/callback", %{
          "error" => "access_denied",
          "error_description" => "User cancelled"
        })

      assert redirected_to(conn) == ~p"/users/log-in"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "User cancelled"
    end
  end
end
