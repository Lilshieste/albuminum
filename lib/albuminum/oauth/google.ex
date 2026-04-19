defmodule Albuminum.OAuth.Google do
  @moduledoc """
  Google OAuth2 client for authentication and Google Photos API access.
  """

  @doc """
  Creates a new OAuth2 client with Google configuration.
  """
  def client do
    OAuth2.Client.new(
      strategy: OAuth2.Strategy.AuthCode,
      client_id: config(:client_id),
      client_secret: config(:client_secret),
      redirect_uri: config(:redirect_uri),
      site: "https://accounts.google.com",
      authorize_url: "/o/oauth2/v2/auth",
      token_url: "https://oauth2.googleapis.com/token",
      # Google requires credentials in POST body, not Basic auth header
      token_method: :post
    )
    |> OAuth2.Client.put_serializer("application/json", Jason)
  end

  @doc """
  Generates the Google OAuth authorization URL for login.
  Uses minimal scopes - just enough to identify user.
  """
  def authorize_url_for_login! do
    client()
    |> OAuth2.Client.authorize_url!(
      scope: login_scope(),
      access_type: "offline",
      prompt: "consent"
    )
  end

  @doc """
  Generates the Google OAuth authorization URL for Photos access.
  Includes photos scope and uses incremental auth.
  """
  def authorize_url_for_photos! do
    client()
    |> OAuth2.Client.authorize_url!(
      scope: photos_scope(),
      access_type: "offline",
      prompt: "consent",
      include_granted_scopes: "true"
    )
  end

  @doc """
  Exchanges authorization code for access token.
  """
  def get_token!(code) do
    client()
    |> OAuth2.Client.put_param(:code, code)
    |> OAuth2.Client.put_param(:redirect_uri, config(:redirect_uri))
    |> OAuth2.Client.get_token()
    |> case do
      {:ok, client} -> client
      {:error, %OAuth2.Response{body: body}} ->
        require Logger
        Logger.error("Google OAuth token error: #{inspect(body)}")
        raise "Google OAuth failed: #{inspect(body)}"
      {:error, %OAuth2.Error{reason: reason}} ->
        require Logger
        Logger.error("Google OAuth error: #{inspect(reason)}")
        raise "Google OAuth failed: #{inspect(reason)}"
    end
  end

  @doc """
  Refreshes an expired access token using the refresh token.
  Returns {:ok, client} or {:error, reason}.
  """
  def refresh_token(refresh_token) do
    # Use Refresh strategy instead of AuthCode for token refresh
    OAuth2.Client.new(
      strategy: OAuth2.Strategy.Refresh,
      client_id: config(:client_id),
      client_secret: config(:client_secret),
      site: "https://accounts.google.com",
      token_url: "https://oauth2.googleapis.com/token",
      token_method: :post
    )
    |> OAuth2.Client.put_param(:refresh_token, refresh_token)
    |> OAuth2.Client.put_serializer("application/json", Jason)
    |> OAuth2.Client.get_token()
  end

  @doc """
  Fetches user info from Google.
  Returns map with id, email, name, picture.
  """
  def get_user_info!(client) do
    {:ok, %OAuth2.Response{body: body}} =
      OAuth2.Client.get(client, "https://www.googleapis.com/oauth2/v2/userinfo")

    body
  end

  @doc """
  Minimal scopes for login - just identify user.
  """
  def login_scope do
    "openid email profile"
  end

  @doc """
  Scopes for Google Photos access.
  """
  def photos_scope do
    "https://www.googleapis.com/auth/photospicker.mediaitems.readonly"
  end

  defp config(key) do
    Application.fetch_env!(:albuminum, __MODULE__)[key]
  end
end
