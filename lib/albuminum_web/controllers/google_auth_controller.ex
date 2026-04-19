defmodule AlbuminumWeb.GoogleAuthController do
  use AlbuminumWeb, :controller

  alias Albuminum.Accounts
  alias Albuminum.OAuth.Google
  alias AlbuminumWeb.UserAuth

  @doc """
  Redirects to Google OAuth for login (minimal scopes).
  """
  def request(conn, _params) do
    redirect(conn, external: Google.authorize_url_for_login!())
  end

  @doc """
  Redirects to Google OAuth for Photos access (incremental auth).
  User must already be logged in.
  """
  def connect_photos(conn, params) do
    conn
    |> put_session(:google_photos_return_to, params["return_to"])
    |> redirect(external: Google.authorize_url_for_photos!())
  end

  @doc """
  Handles callback from Google OAuth.
  """
  def callback(conn, %{"code" => code}) do
    client = Google.get_token!(code)
    user_info = Google.get_user_info!(client)

    case conn.assigns[:current_scope] do
      nil ->
        handle_login_callback(conn, user_info, client.token)

      scope ->
        handle_photos_callback(conn, scope.user, client.token)
    end
  end

  def callback(conn, %{"error" => error, "error_description" => description}) do
    conn
    |> put_flash(:error, "Google auth error: #{error} - #{description}")
    |> redirect(to: ~p"/users/log-in")
  end

  def callback(conn, %{"error" => error}) do
    conn
    |> put_flash(:error, "Google auth error: #{error}")
    |> redirect(to: ~p"/users/log-in")
  end

  defp handle_login_callback(conn, user_info, token) do
    case Accounts.find_or_create_google_user(user_info, token) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Welcome!")
        |> UserAuth.log_in_user(user)

      {:error, reason} ->
        conn
        |> put_flash(:error, "Authentication failed: #{inspect(reason)}")
        |> redirect(to: ~p"/users/log-in")
    end
  end

  defp handle_photos_callback(conn, user, token) do
    Accounts.upsert_oauth_token(user, "google", token)

    return_to = get_session(conn, :google_photos_return_to) || ~p"/albums"

    conn
    |> delete_session(:google_photos_return_to)
    |> put_flash(:info, "Google Photos connected!")
    |> redirect(to: return_to)
  end
end
