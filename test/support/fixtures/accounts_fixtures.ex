defmodule Albuminum.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Albuminum.Accounts` context.
  """

  import Ecto.Query

  alias Albuminum.Accounts
  alias Albuminum.Accounts.Scope

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email()
    })
  end

  def unconfirmed_user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Accounts.register_user()

    user
  end

  def user_fixture(attrs \\ %{}) do
    user = unconfirmed_user_fixture(attrs)

    token =
      extract_user_token(fn url ->
        Accounts.deliver_login_instructions(user, url)
      end)

    {:ok, {user, _expired_tokens}} =
      Accounts.login_user_by_magic_link(token)

    user
  end

  def user_scope_fixture do
    user = user_fixture()
    user_scope_fixture(user)
  end

  def user_scope_fixture(user) do
    Scope.for_user(user)
  end

  def set_password(user) do
    {:ok, {user, _expired_tokens}} =
      Accounts.update_user_password(user, %{password: valid_user_password()})

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  def override_token_authenticated_at(token, authenticated_at) when is_binary(token) do
    Albuminum.Repo.update_all(
      from(t in Accounts.UserToken,
        where: t.token == ^token
      ),
      set: [authenticated_at: authenticated_at]
    )
  end

  def generate_user_magic_link_token(user) do
    {encoded_token, user_token} = Accounts.UserToken.build_email_token(user, "login")
    Albuminum.Repo.insert!(user_token)
    {encoded_token, user_token.token}
  end

  def offset_user_token(token, amount_to_add, unit) do
    dt = DateTime.add(DateTime.utc_now(:second), amount_to_add, unit)

    Albuminum.Repo.update_all(
      from(ut in Accounts.UserToken, where: ut.token == ^token),
      set: [inserted_at: dt, authenticated_at: dt]
    )
  end

  # Google OAuth fixtures

  def unique_google_id, do: "google_#{System.unique_integer([:positive])}"

  def google_user_info_fixture(attrs \\ %{}) do
    Map.merge(
      %{
        "id" => unique_google_id(),
        "email" => unique_user_email(),
        "name" => "Test User",
        "picture" => "https://example.com/photo.jpg"
      },
      attrs
    )
  end

  def oauth_token_fixture(attrs \\ %{}) do
    defaults = %OAuth2.AccessToken{
      access_token: "test_access_token_#{System.unique_integer()}",
      refresh_token: "test_refresh_token_#{System.unique_integer()}",
      expires_at: System.system_time(:second) + 3600,
      token_type: "Bearer",
      other_params: %{"scope" => "openid email profile"}
    }

    struct(defaults, attrs)
  end

  def google_user_fixture(attrs \\ %{}) do
    user_info = google_user_info_fixture(attrs)
    token = oauth_token_fixture()

    {:ok, user} = Accounts.find_or_create_google_user(user_info, token)
    user
  end
end
