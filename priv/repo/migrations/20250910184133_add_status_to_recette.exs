defmodule BauleBio.Repo.Migrations.AddStatusToRecette do
  use Ecto.Migration

  def change do
    alter table(:recettes) do
      add :status, :string, default: "draft", null: false
    end
  end
end
