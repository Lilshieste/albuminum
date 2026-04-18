defmodule Albuminum.Accounts.OAuthToken do
  @moduledoc """
  Schema for storing OAuth tokens (access + refresh) for external providers.
  Tokens are encrypted at rest using AES-256-GCM.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Albuminum.Accounts.TokenEncryption
  alias Albuminum.Accounts.User

  schema "oauth_tokens" do
    field :provider, :string
    field :access_token, :binary
    field :refresh_token, :binary
    field :expires_at, :utc_datetime
    field :scope, :string

    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  def changeset(oauth_token, attrs) do
    oauth_token
    |> cast(attrs, [:provider, :access_token, :refresh_token, :expires_at, :scope, :user_id])
    |> validate_required([:provider, :access_token, :user_id])
    |> unique_constraint([:user_id, :provider])
    |> encrypt_tokens()
  end

  defp encrypt_tokens(changeset) do
    changeset
    |> maybe_encrypt(:access_token)
    |> maybe_encrypt(:refresh_token)
  end

  defp maybe_encrypt(changeset, field) do
    case get_change(changeset, field) do
      nil -> changeset
      value when is_binary(value) -> put_change(changeset, field, TokenEncryption.encrypt(value))
    end
  end

  def decrypt_access_token(%__MODULE__{access_token: encrypted}) do
    TokenEncryption.decrypt(encrypted)
  end

  def decrypt_refresh_token(%__MODULE__{refresh_token: encrypted}) do
    TokenEncryption.decrypt(encrypted)
  end
end
