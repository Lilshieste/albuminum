defmodule Albuminum.Accounts.TokenEncryptionTest do
  use ExUnit.Case, async: true

  alias Albuminum.Accounts.TokenEncryption

  describe "encrypt/1 and decrypt/1" do
    test "encrypts and decrypts a token" do
      original = "my_secret_token"
      encrypted = TokenEncryption.encrypt(original)

      assert encrypted != original
      assert is_binary(encrypted)
      assert TokenEncryption.decrypt(encrypted) == original
    end

    test "handles nil values" do
      assert TokenEncryption.encrypt(nil) == nil
      assert TokenEncryption.decrypt(nil) == nil
    end

    test "returns nil for invalid encrypted data" do
      assert TokenEncryption.decrypt("invalid") == nil
      assert TokenEncryption.decrypt(<<1, 2, 3>>) == nil
    end

    test "produces different ciphertext for same plaintext (due to random IV)" do
      original = "my_secret_token"
      encrypted1 = TokenEncryption.encrypt(original)
      encrypted2 = TokenEncryption.encrypt(original)

      assert encrypted1 != encrypted2
      assert TokenEncryption.decrypt(encrypted1) == original
      assert TokenEncryption.decrypt(encrypted2) == original
    end
  end
end
