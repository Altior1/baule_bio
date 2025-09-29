defmodule BauleBio.Partage do
  @moduledoc """
  The Partage context.
  """

  import Ecto.Query, warn: false
  alias BauleBio.Repo

  alias BauleBio.Partage.Recette
  alias BauleBio.Partage.Ingredient

  @doc """
  Returns the list of recettes.

  ## Examples

      iex> list_recettes()
      [%Recette{}, ...]

  """
  def list_recettes do
    Repo.all(Recette)
  end

  def list_recettes_with_ingredients do
    Repo.all(from r in Recette, preload: [:ingredients])
  end

  @doc """
  Retourne la liste des recettes publiées (status :published).
  """
  def list_recettes_published do
    Repo.all(from r in Recette, where: r.status == :published)
  end

  @doc """
  Retourne la liste des recettes à valider (status :submitted).
  """
  def list_recettes_to_validate do
    Repo.all(from r in Recette, where: r.status == :submitted)
  end

  @doc """
  Gets a single recette.

  Raises `Ecto.NoResultsError` if the Recette does not exist.

  ## Examples

      iex> get_recette!(123)
      %Recette{}

      iex> get_recette!(456)
      ** (Ecto.NoResultsError)

  """
  def get_recette!(id), do: Repo.get!(Recette, id)

  def get_recette_with_ingredients!(id) do
    Repo.one!(
      from r in Recette,
        where: r.id == ^id,
        preload: [:ingredients]
    )
  end

  @doc """
  Creates a recette.

  ## Examples

      iex> create_recette(%{field: value})
      {:ok, %Recette{}}

      iex> create_recette(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_recette(attrs) do
    %Recette{}
    |> Recette.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  permet de créer plus facilement une recette avec plusieurs ingrédients
  """
  def create_recette_many(attrs \\ %{}) do
    %Recette{}
    |> Recette.changeset_for_many(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a recette.

  ## Examples

      iex> update_recette(recette, %{field: new_value})
      {:ok, %Recette{}}

      iex> update_recette(recette, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_recette(%Recette{} = recette, attrs) do
    recette
    |> Recette.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  permet de mettre à jour plus facilement une recette avec plusieurs ingrédients
  """
  def update_recette_many(%Recette{} = recette, attrs) do
    recette
    |> Recette.changeset_for_many(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a recette.

  ## Examples

      iex> delete_recette(recette)
      {:ok, %Recette{}}

      iex> delete_recette(recette)
      {:error, %Ecto.Changeset{}}

  """
  def delete_recette(%Recette{} = recette) do
    Repo.delete(recette)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking recette changes.

  ## Examples

      iex> change_recette(recette)
      %Ecto.Changeset{data: %Recette{}}

  """
  def change_recette(%Recette{} = recette, attrs \\ %{}) do
    Recette.changeset(recette, attrs)
  end

  def change_recette_many(
        %Recette{} = recette,
        attrs \\ %{}
      ) do
    Recette.prepare_changeset_for_many(recette, attrs)
  end

  def list_ingredients do
    Repo.all(Ingredient)
  end

  def get_ingredient!(id) do
    Repo.get!(Ingredient, id)
  end

  def change_ingredient(%Ingredient{} = ingredient, attrs \\ %{}) do
    Ingredient.changeset(ingredient, attrs)
  end

  def create_ingredient(attrs \\ %{}) do
    %Ingredient{}
    |> Ingredient.changeset(attrs)
    |> Repo.insert()
  end

  def update_ingredient(%Ingredient{} = ingredient, attrs) do
    ingredient
    |> Ingredient.changeset(attrs)
    |> Repo.update()
  end

  def delete_ingredient(%Ingredient{} = ingredient) do
    Repo.delete(ingredient)
  end
end
