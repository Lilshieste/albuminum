defmodule Albuminum.Repo.Migrations.AddMetadataToImages do
  use Ecto.Migration

  def change do
    alter table(:images) do
      add :alt_text, :text
      add :caption, :text
    end
  end
end
