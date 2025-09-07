defmodule BauleBio.Partage.Recette do
  @moduledoc """
  The Recette schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "recettes" do
    field :ingredient, :map
    field :nom, :string
    field :description, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(recette, attrs) do
    recette
    |> cast(attrs, [:ingredient, :nom, :description])
    |> validate_required([:nom, :description])
  end
end
