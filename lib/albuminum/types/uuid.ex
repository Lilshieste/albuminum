defmodule Albuminum.Types.UUID do
  @moduledoc """
  Ecto type for UUIDs stored as human-readable TEXT in SQLite.

  Ecto's built-in :binary_id stores UUIDs as 16-byte BLOBs, which are
  opaque in SQLite tooling. This type uses :string storage so UUIDs are
  stored as "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" TEXT columns instead.
  """

  use Ecto.Type

  @impl true
  def type, do: :string

  @impl true
  def cast(value), do: Ecto.UUID.cast(value)

  @impl true
  def load(value) when is_binary(value), do: Ecto.UUID.cast(value)
  def load(_), do: :error

  @impl true
  def dump(value) when is_binary(value) do
    case Ecto.UUID.cast(value) do
      {:ok, uuid} -> {:ok, uuid}
      :error -> :error
    end
  end

  def dump(_), do: :error

  @impl true
  def autogenerate, do: Ecto.UUID.generate()
end
