defmodule BauleBio.PartageFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BauleBio.Partage` context.
  """

  @doc """
  Generate a recette.
  """
  def recette_fixture(attrs \\ %{}) do
    {:ok, recette} =
      attrs
      |> Enum.into(%{
        description: "some description",
        ingredient: %{},
        nom: "some nom"
      })
      |> BauleBio.Partage.create_recette()

    recette
  end
end
