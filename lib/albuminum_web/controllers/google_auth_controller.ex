defmodule AlbuminumWeb.GoogleAuthController do
  use AlbuminumWeb, :controller

  alias Albuminum.Accounts
  alias Albuminum.OAuth.Google
  alias AlbuminumWeb.UserAuth

  @doc """
  Redirects to Google OAuth authorization page.
  """
  def request(conn, _params) do
    redirect(conn, external: Google.authorize_url!())
  end

  @doc """
  Handles callback from Google OAuth.
  Exchanges code for token, finds/creates user, logs them in.
  """
  def callback(conn, %{"code" => code}) do
    client = Google.get_token!(code)
    user_info = Google.get_user_info!(client)

    case Accounts.find_or_create_google_user(user_info, client.token) do
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
end
