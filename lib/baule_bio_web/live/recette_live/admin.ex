defmodule BauleBioWeb.RecetteLive.Admin do
  use BauleBioWeb, :live_view

  alias BauleBio.Partage

  @impl true
  def mount(_params, _session, socket) do
    current_scope = socket.assigns[:current_scope]

    # Vérifier que l'utilisateur est connecté et admin
    if current_scope && current_scope.utilisateur && current_scope.utilisateur.role == "admin" do
      {:ok,
       socket
       |> assign(:page_title, "Administration - Validation des recettes")
       |> stream(:recettes, Partage.list_recettes_to_validate())}
    else
      {:ok,
       socket
       |> put_flash(:error, "Accès non autorisé")
       |> push_navigate(to: ~p"/")}
    end
  end

  @impl true
  def handle_event("publish", %{"id" => id}, socket) do
    recette = Partage.get_recette!(id)
    {:ok, _} = Partage.update_recette(recette, %{status: :published})

    {:noreply,
     socket
     |> put_flash(:info, "Recette '#{recette.nom}' publiée avec succès")
     |> stream(:recettes, Partage.list_recettes_to_validate(), reset: true)}
  end

  def handle_event("reject", %{"id" => id}, socket) do
    recette = Partage.get_recette!(id)
    {:ok, _} = Partage.update_recette(recette, %{status: :draft})

    {:noreply,
     socket
     |> put_flash(:info, "Recette '#{recette.nom}' rejetée")
     |> stream(:recettes, Partage.list_recettes_to_validate(), reset: true)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Administration - Validation des recettes
        <:subtitle>Recettes en attente de validation</:subtitle>
      </.header>

      <div id="recettes-admin" phx-update="stream">
        <div :for={{id, recette} <- @streams.recettes} id={id} class="border rounded-lg p-4 mb-4">
          <div class="flex justify-between items-start">
            <div class="flex-1">
              <h3 class="text-lg font-semibold">{recette.nom}</h3>
              <p class="text-gray-600 mt-2">{recette.description}</p>
              <p class="text-sm text-gray-500 mt-2">
                Soumise le: {Calendar.strftime(recette.inserted_at, "%d/%m/%Y à %H:%M")}
              </p>
            </div>
            <div class="flex gap-2 ml-4">
              <.button
                phx-click="publish"
                phx-value-id={recette.id}
                variant="primary"
                data-confirm="Êtes-vous sûr de vouloir publier cette recette ?"
              >
                <.icon name="hero-check" class="w-4 h-4 mr-1" /> Publier
              </.button>
              <.button
                phx-click="reject"
                phx-value-id={recette.id}
                variant="primary"
                data-confirm="Êtes-vous sûr de vouloir rejeter cette recette ?"
              >
                <.icon name="hero-x-mark" class="w-4 h-4 mr-1" /> Rejeter
              </.button>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
