defmodule Albuminum.Repo.Migrations.AddIsActiveToAlbumShares do
  use Ecto.Migration

  def change do
    alter table(:album_shares) do
      add :is_active, :boolean, default: true, null: false
    end
  end
end
