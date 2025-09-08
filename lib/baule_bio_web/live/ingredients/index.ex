defmodule BauleBioWeb.Ingredients.Index do
  @moduledoc """
  La vue de la liste des ingrédients
  """
  use BauleBioWeb, :live_view

  alias BauleBio.Partage

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Ingredients
        <:subtitle>Manage your ingredients here.</:subtitle>
      </.header>

      <table>
        <tr>
          <th>Name</th>
          <th>Actions</th>
        </tr>
        <%= for ingredient <- @ingredients do %>
          <tr>
            <td>
              <td>{ingredient.nom}</td>
              <.link navigate={~p"/ingredients/#{ingredient.id}/edit"}>Edit</.link>
            </td>
          </tr>
        <% end %>
      </table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    ingredients = Partage.list_ingredients()
    {:ok, assign(socket, ingredients: ingredients)}
  end
end
