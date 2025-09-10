defmodule BauleBio.Partage.Recette do
  @moduledoc """
  The Recette schema.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias BauleBio.Partage

  schema "recettes" do
    # à supprimer plus tard
    field :ingredient, :map
    field :nom, :string
    field :description, :string
    field :list_ingredients, {:array, :string}, virtual: true
    field :status, Ecto.Enum, values: [:draft, :submitted, :published], default: :draft

    many_to_many :ingredients, BauleBio.Partage.Ingredient,
      join_through: IngredientRecette,
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(recette, attrs) do
    recette
    |> cast(attrs, [:nom, :description])
    |> cast_assoc(:ingredients, with: &BauleBio.Partage.Ingredient.changeset/2)
    |> validate_required([:nom, :description])
  end

  def prepare_changeset_for_many(recette, attrs) do
    changeset(recette, attrs)
    |> change(list_ingredients: Enum.map(recette.ingredients, & &1.id))
  end

  def changeset_for_many(recette, attrs) do
    mount_assoc = fn changeset ->
      attrs["list_ingredients"]
      |> case do
        nil ->
          changeset |> add_error(:list_ingredients, "doit contenir au moins un ingrédient")

        list ->
          changeset |> put_assoc(:ingredients, Enum.map(list || [], &Partage.get_ingredient!(&1)))
      end
    end

    changeset(recette, attrs)
    |> mount_assoc.()
  end
end
