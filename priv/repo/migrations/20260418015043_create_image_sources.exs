defmodule Albuminum.Repo.Migrations.CreateImageSources do
  use Ecto.Migration

  def change do
    create table(:image_sources) do
      add :image_id, references(:images, on_delete: :delete_all), null: false
      add :provider, :string, null: false
      add :external_id, :string, null: false
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:image_sources, [:image_id])
    create unique_index(:image_sources, [:provider, :external_id])
  end
end
