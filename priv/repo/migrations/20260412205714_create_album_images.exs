defmodule Albuminum.Repo.Migrations.CreateAlbumImages do
  use Ecto.Migration

  def change do
    create table(:album_images) do
      add :position, :integer
      add :album_id, references(:albums, on_delete: :nothing)
      add :image_id, references(:images, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:album_images, [:album_id])
    create index(:album_images, [:image_id])
  end
end
