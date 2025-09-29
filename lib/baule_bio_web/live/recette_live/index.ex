defmodule BauleBioWeb.RecetteLive.Index do
  use BauleBioWeb, :live_view

  alias BauleBio.Partage

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Recettes
        <:actions>
          <%= if @current_scope do %>
            <.link navigate={~p"/recettes/new"} class="btn btn-primary">
              <.icon name="hero-plus" class="size-4" /> New Recette
            </.link>
          <% end %>
        </:actions>
      </.header>

      <.table
        id="recettes"
        rows={@streams.recettes}
        row_click={fn {_id, recette} -> JS.navigate(~p"/recettes/#{recette}") end}
      >
        <:col :let={{_id, recette}} label="Nom">{recette.nom}</:col>
        <:col :let={{_id, recette}} label="Description">{recette.description}</:col>
        <:action :let={{_id, recette}}>
          <div class="sr-only">
            <.link navigate={~p"/recettes/#{recette}"}>Show</.link>
          </div>
          <%= if @current_scope do %>
            <.link navigate={~p"/recettes/#{recette}/edit"}>Edit</.link>
          <% end %>
        </:action>
        <:action :let={{id, recette}} :if={@current_scope}>
          <.link
            phx-click={JS.push("delete", value: %{id: recette.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Recettes")
     |> stream(:recettes, list_recettes())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    recette = Partage.get_recette!(id)
    {:ok, _} = Partage.delete_recette(recette)

    {:noreply, stream_delete(socket, :recettes, recette)}
  end

  defp list_recettes() do
    Partage.list_recettes_published()
  end
end
