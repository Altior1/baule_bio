defmodule BauleBio.Repo.Migrations.CreateIngredients do
  use Ecto.Migration

  def change do
    create table(:ingredients) do
      add :nom, :string
      add :disponible, :boolean, default: false, null: false
      add :date_debut_disponible, :date
      add :date_fin_disponible, :date
      add :description, :string

      timestamps(type: :utc_datetime)
    end
  end
end
