defmodule BauleBio.Partage do
  @moduledoc """
  The Partage context.
  """

  import Ecto.Query, warn: false
  alias BauleBio.Repo

  alias BauleBio.Partage.Recette

  @doc """
  Returns the list of recettes.

  ## Examples

      iex> list_recettes()
      [%Recette{}, ...]

  """
  def list_recettes do
    Repo.all(Recette)
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
end
