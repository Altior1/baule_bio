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
          <.link navigate={~p"/recettes"} class="btn btn-ghost">
            <.icon name="hero-arrow-left" class="size-4" />
          </.link>
          <%= if @current_scope do %>
            <.link navigate={~p"/recettes/#{@recette}/edit?return_to=show"} class="btn btn-primary">
              <.icon name="hero-pencil-square" class="size-4" /> Edit recette
            </.link>
          <% end %>
        </:actions>
      </.header>

      <.list>
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
