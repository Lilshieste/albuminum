defmodule Albuminum.Repo.Migrations.AddUserIdToAlbums do
  use Ecto.Migration

  def change do
    alter table(:albums) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
    end

    create index(:albums, [:user_id])
  end
end
