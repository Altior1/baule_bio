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

    timestamps(type: :utc_datetime)
  end
end
