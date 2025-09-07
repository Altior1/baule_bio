defmodule BauleBioWeb.RecetteLive.Show do
  use BauleBioWeb, :live_view

  alias BauleBio.Partage

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Recette {@recette.id}
        <:subtitle>This is a recette record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/recettes"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/recettes/#{@recette}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit recette
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Ingredient">{@recette.ingredient}</:item>
        <:item title="Nom">{@recette.nom}</:item>
        <:item title="Description">{@recette.description}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Recette")
     |> assign(:recette, Partage.get_recette!(id))}
  end
end
