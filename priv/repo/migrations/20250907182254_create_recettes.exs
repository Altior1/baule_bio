defmodule BauleBio.Repo.Migrations.CreateRecettes do
  use Ecto.Migration

  def change do
    create table(:recettes) do
      add :ingredient, :map
      add :nom, :string
      add :description, :string

      timestamps(type: :utc_datetime)
    end
  end
end
