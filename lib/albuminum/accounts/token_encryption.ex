defmodule Albuminum.Accounts.TokenEncryption do
  @moduledoc """
  Encrypts and decrypts OAuth tokens using AES-256-GCM.
  Uses the app's secret_key_base for key derivation.
  """

  @aad "AES256GCM-oauth-token"

  def encrypt(nil), do: nil

  def encrypt(plaintext) when is_binary(plaintext) do
    key = derive_key()
    iv = :crypto.strong_rand_bytes(12)

    {ciphertext, tag} =
      :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, plaintext, @aad, true)

    iv <> tag <> ciphertext
  end

  def decrypt(nil), do: nil

  def decrypt(<<iv::binary-12, tag::binary-16, ciphertext::binary>>) do
    key = derive_key()
    :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, ciphertext, @aad, tag, false)
  end

  def decrypt(_invalid), do: nil

  defp derive_key do
    secret = Application.fetch_env!(:albuminum, AlbuminumWeb.Endpoint)[:secret_key_base]
    :crypto.hash(:sha256, secret)
  end
end
