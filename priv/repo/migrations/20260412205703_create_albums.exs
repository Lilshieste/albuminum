defmodule Albuminum.Repo.Migrations.CreateAlbums do
  use Ecto.Migration

  def change do
    create table(:albums) do
      add :name, :string
      add :description, :text

      timestamps(type: :utc_datetime)
    end
  end
end
