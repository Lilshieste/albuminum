defmodule Albuminum.Repo.Migrations.CreateAlbumShares do
  use Ecto.Migration

  def change do
    create table(:album_shares) do
      add :token, :string, null: false
      add :album_id, references(:albums, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:album_shares, [:token])
    create unique_index(:album_shares, [:album_id])
  end
end
