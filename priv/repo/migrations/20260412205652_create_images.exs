defmodule Albuminum.Repo.Migrations.CreateImages do
  use Ecto.Migration

  def change do
    create table(:images) do
      add :filename, :string
      add :path, :string

      timestamps(type: :utc_datetime)
    end
  end
end
