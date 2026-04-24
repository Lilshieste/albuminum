defmodule Albuminum.Repo.Migrations.CreateImageTags do
  use Ecto.Migration

  def change do
    create table(:image_tags, primary_key: false) do
      add :image_id, references(:images, on_delete: :delete_all), null: false
      add :tag_id, references(:tags, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:image_tags, [:image_id])
    create index(:image_tags, [:tag_id])
    create unique_index(:image_tags, [:image_id, :tag_id])
  end
end
