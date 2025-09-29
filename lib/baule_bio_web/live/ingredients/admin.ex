defmodule BauleBioWeb.Ingredients.Admin do
  use BauleBioWeb, :live_view

  alias BauleBio.Partage

  @impl true
  def mount(_params, _session, socket) do
    current_scope = socket.assigns[:current_scope]

    # Vérifier que l'utilisateur est connecté et admin
    if current_scope && current_scope.utilisateur && current_scope.utilisateur.role == "admin" do
      {:ok,
       socket
       |> assign(:page_title, "Administration - Gestion des ingrédients")
       |> stream(:ingredients, Partage.list_ingredients())}
    else
      {:ok,
       socket
       |> put_flash(:error, "Accès non autorisé")
       |> push_navigate(to: ~p"/")}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    ingredient = Partage.get_ingredient!(id)

    case Partage.delete_ingredient(ingredient) do
      {:ok, _ingredient} ->
        {:noreply,
         socket
         |> put_flash(:info, "Ingrédient supprimé avec succès")
         |> stream_delete(:ingredients, ingredient)}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "Impossible de supprimer cet ingrédient (utilisé dans des recettes)"
         )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Administration - Gestion des ingrédients
        <:subtitle>Gérer les ingrédients disponibles</:subtitle>
        <:actions>
          <.button navigate={~p"/admin/ingredients/new"} variant="primary">
            <.icon name="hero-plus" class="w-4 h-4 mr-1" /> Nouvel ingrédient
          </.button>
        </:actions>
      </.header>

      <div class="mt-8">
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div :for={{id, ingredient} <- @streams.ingredients} id={id} class="border rounded-lg p-4">
            <div class="flex justify-between items-start">
              <div class="flex-1">
                <h3 class="text-lg font-semibold">{ingredient.nom}</h3>
                <p class="text-gray-600 text-sm mt-1">{ingredient.description}</p>

                <div class="mt-3 space-y-1">
                  <div class="flex items-center gap-2">
                    <span class={"badge " <> if ingredient.disponible, do: "badge-success", else: "badge-error"}>
                      {if ingredient.disponible, do: "Disponible", else: "Indisponible"}
                    </span>
                  </div>

                  <%= if ingredient.date_debut_disponible && ingredient.date_fin_disponible do %>
                    <p class="text-xs text-gray-500">
                      Saison : {Date.to_string(ingredient.date_debut_disponible)} → {Date.to_string(
                        ingredient.date_fin_disponible
                      )}
                    </p>
                  <% end %>
                </div>
              </div>

              <div class="flex gap-2 ml-4">
                <.button
                  navigate={~p"/admin/ingredients/#{ingredient.id}/edit"}
                  class="btn btn-sm"
                >
                  <.icon name="hero-pencil" class="w-4 h-4" />
                </.button>

                <.button
                  phx-click="delete"
                  phx-value-id={ingredient.id}
                  class="btn btn-sm btn-error"
                  data-confirm="Êtes-vous sûr de vouloir supprimer cet ingrédient ?"
                >
                  <.icon name="hero-trash" class="w-4 h-4" />
                </.button>
              </div>
            </div>
          </div>
        </div>

        <%= if Enum.empty?(@streams.ingredients) do %>
          <div class="text-center py-12">
            <.icon name="hero-beaker" class="w-12 h-12 text-gray-400 mx-auto mb-4" />
            <h3 class="text-lg font-medium text-gray-900 mb-2">Aucun ingrédient</h3>
            <p class="text-gray-500 mb-6">Commencez par ajouter des ingrédients pour vos recettes.</p>
            <.button navigate={~p"/admin/ingredients/new"} variant="primary">
              <.icon name="hero-plus" class="w-4 h-4 mr-1" /> Ajouter le premier ingrédient
            </.button>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end
end
