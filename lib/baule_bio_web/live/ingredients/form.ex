defmodule BauleBioWeb.Ingredients.Form do
  @moduledoc """
  La vue pour créer ou éditer un ingrédient
  """

  use BauleBioWeb, :live_view
  alias BauleBio.Partage
  alias BauleBio.Partage.Ingredient

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Ingredient Form
        <:subtitle>Create or edit an ingredient</:subtitle>
      </.header>

      <.form for={@form} phx-submit="save">
        <.input field={@form[:nom]} label="Name" />
        <.input field={@form[:disponible]} type="checkbox" label="Available" />
        <.input field={@form[:date_debut_disponible]} type="date" label="Start Date of Availability" />
        <.input field={@form[:date_fin_disponible]} type="date" label="End Date of Availability" />
        <.input field={@form[:description]} type="textarea" label="Description" />

        <.button>Save</.button>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    changeset = Partage.change_ingredient(%Ingredient{})
    {:ok, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"ingredient" => ingredient_params}, socket) do
    case Partage.create_ingredient(ingredient_params) do
      {:ok, ingredient} ->
        {:noreply, redirect(socket, to: ~p"/ingredients/#{ingredient.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
