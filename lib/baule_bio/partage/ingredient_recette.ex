defmodule BauleBio.Partage.IngredientRecette do
  @moduledoc """
  Gère la table de jointure entre les ingrédients et les recettes.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "ingredients_recettes" do
    belongs_to :ingredient, BauleBio.Partage.Ingredient
    belongs_to :recette, BauleBio.Partage.Recette
    field :quantite, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(ingredient_recette, attrs) do
    ingredient_recette
    |> cast(attrs, [:quantite])
    |> validate_required([:quantite])
    |> foreign_key_constraint(:ingredient_id)
    |> foreign_key_constraint(:recette_id)
  end
end
