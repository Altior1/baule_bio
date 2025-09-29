defmodule BauleBioWeb.Ingredients.AdminForm do
  use BauleBioWeb, :live_view

  alias BauleBio.Partage
  alias BauleBio.Partage.Ingredient

  @impl true
  def mount(params, _session, socket) do
    current_scope = socket.assigns[:current_scope]

    # Vérifier que l'utilisateur est connecté et admin
    if current_scope && current_scope.utilisateur && current_scope.utilisateur.role == "admin" do
      {:ok, apply_action(socket, socket.assigns.live_action, params)}
    else
      {:ok,
       socket
       |> put_flash(:error, "Accès non autorisé")
       |> push_navigate(to: ~p"/")}
    end
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    ingredient = Partage.get_ingredient!(id)

    socket
    |> assign(:page_title, "Modifier l'ingrédient")
    |> assign(:ingredient, ingredient)
    |> assign(:form, to_form(Partage.change_ingredient(ingredient)))
  end

  defp apply_action(socket, :new, _params) do
    ingredient = %Ingredient{}

    socket
    |> assign(:page_title, "Nouvel ingrédient")
    |> assign(:ingredient, ingredient)
    |> assign(:form, to_form(Partage.change_ingredient(ingredient)))
  end

  @impl true
  def handle_event("validate", %{"ingredient" => ingredient_params}, socket) do
    changeset = Partage.change_ingredient(socket.assigns.ingredient, ingredient_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"ingredient" => ingredient_params}, socket) do
    save_ingredient(socket, socket.assigns.live_action, ingredient_params)
  end

  defp save_ingredient(socket, :edit, ingredient_params) do
    case Partage.update_ingredient(socket.assigns.ingredient, ingredient_params) do
      {:ok, _ingredient} ->
        {:noreply,
         socket
         |> put_flash(:info, "Ingrédient modifié avec succès")
         |> push_navigate(to: ~p"/admin/ingredients")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_ingredient(socket, :new, ingredient_params) do
    case Partage.create_ingredient(ingredient_params) do
      {:ok, _ingredient} ->
        {:noreply,
         socket
         |> put_flash(:info, "Ingrédient créé avec succès")
         |> push_navigate(to: ~p"/admin/ingredients")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Gérer les ingrédients disponibles</:subtitle>
      </.header>

      <.form
        for={@form}
        id="ingredient-form"
        phx-change="validate"
        phx-submit="save"
        class="max-w-2xl"
      >
        <div class="grid grid-cols-1 gap-6">
          <.input field={@form[:nom]} type="text" label="Nom de l'ingrédient" required />

          <.input
            field={@form[:description]}
            type="textarea"
            label="Description"
            placeholder="Description de l'ingrédient, ses bienfaits, etc."
            rows="3"
          />

          <div class="flex items-center gap-2">
            <.input field={@form[:disponible]} type="checkbox" label="Disponible actuellement" />
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <.input
              field={@form[:date_debut_disponible]}
              type="date"
              label="Date de début de disponibilité"
            />

            <.input
              field={@form[:date_fin_disponible]}
              type="date"
              label="Date de fin de disponibilité"
            />
          </div>
        </div>

        <div class="flex items-center gap-4 mt-8">
          <.button type="submit" variant="primary">
            {if @live_action == :new, do: "Créer l'ingrédient", else: "Modifier l'ingrédient"}
          </.button>

          <.button navigate={~p"/admin/ingredients"} class="btn btn-ghost">
            Annuler
          </.button>
        </div>
      </.form>
    </Layouts.app>
    """
  end
end
