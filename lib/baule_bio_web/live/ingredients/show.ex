defmodule BauleBioWeb.Ingredients.Show do
  @moduledoc """
  La vue pour afficher un ingrédient
  """

  use BauleBioWeb, :live_view

  alias BauleBio.Partage

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Ingredient Details
        <:subtitle>Details and actions for ingredient: {@ingredient.nom}</:subtitle>
      </.header>

      <.link navigate={~p"/ingredients"} class="mt-4 inline-block">
        Back to Ingredients
      </.link>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    ingredient = Partage.get_ingredient!(id)
    {:ok, assign(socket, ingredient: ingredient)}
  end
end
