defmodule BauleBio.Repo.Migrations.CreateIngredientsRecettes do
  use Ecto.Migration

  def change do
    create table(:ingredients_recettes) do
      add :ingredient, references(:ingredients, on_delete: :nothing)
      add :recette, references(:recettes, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:ingredients_recettes, [:ingredient])
    create index(:ingredients_recettes, [:recette])
  end
end
