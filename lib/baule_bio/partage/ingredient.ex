defmodule BauleBio.Partage.Ingredient do
  @moduledoc """
  Gère les ingrédients utilisés dans les recettes.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias BauleBio.Partage.IngredientRecette

  schema "ingredients" do
    field :nom, :string
    field :disponible, :boolean, default: false
    field :date_debut_disponible, :date
    field :date_fin_disponible, :date
    field :description, :string

    many_to_many :recettes, BauleBio.Partage.Recette,
      join_through: IngredientRecette,
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(ingredient, attrs) do
    ingredient
    |> cast(attrs, [:nom, :disponible, :date_debut_disponible, :date_fin_disponible, :description])
    |> validate_required([
      :nom,
      :disponible,
      :date_debut_disponible,
      :date_fin_disponible,
      :description
    ])
  end
end
