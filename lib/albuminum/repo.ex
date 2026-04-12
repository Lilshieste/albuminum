defmodule Albuminum.Repo do
  use Ecto.Repo,
    otp_app: :albuminum,
    adapter: Ecto.Adapters.SQLite3
end
