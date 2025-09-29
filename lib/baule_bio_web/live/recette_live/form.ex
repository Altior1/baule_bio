defmodule BauleBioWeb.RecetteLive.Form do
  use BauleBioWeb, :live_view

  alias BauleBio.Partage
  alias BauleBio.Partage.Recette
  alias BauleBio.Partage.Ingredient

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage recette records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="recette-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:nom]} type="text" label="Nom" />
        <.inputs_for :let={ig} field={@form[:ingredients]}>
          <.input field={ig[:quantite]} type="text" label="Quantite" />
          <.input field={ig[:id]} type="select" label="Ingredient" options={@ingredients} />
        </.inputs_for>

        <.input field={@form[:description]} type="textarea" label="Description" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Recette</.button>
          <.button navigate={return_path(@return_to, @recette)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(:ingredients, Partage.list_ingredients() |> Enum.map(&{&1.nom, &1.id}))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    recette = Partage.get_recette_with_ingredients!(id)

    socket
    |> assign(:page_title, "Edit Recette")
    |> assign(:recette, recette)
    |> assign(:form, to_form(Partage.change_recette_many(recette)))
  end

  defp apply_action(socket, :new, _params) do
    recette = %Recette{ingredients: [%Ingredient{}]}

    socket
    |> assign(:page_title, "New Recette")
    |> assign(:recette, recette)
    |> assign(:form, to_form(Partage.change_recette_many(recette)))
  end

  @impl true
  def handle_event("validate", %{"recette" => recette_params}, socket) do
    changeset = Partage.change_recette(socket.assigns.recette, recette_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"recette" => recette_params}, socket) do
    save_recette(socket, socket.assigns.live_action, recette_params)
  end

  defp save_recette(socket, :edit, recette_params) do
    case Partage.update_recette(socket.assigns.recette, recette_params) do
      {:ok, recette} ->
        {:noreply,
         socket
         |> put_flash(:info, "Recette updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, recette))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_recette(socket, :new, recette_params) do
    # Ajouter l'auteur et définir le statut comme soumis
    current_user = socket.assigns.current_scope.utilisateur

    recette_params =
      Map.merge(recette_params, %{
        "auteur_id" => current_user.id,
        "status" => "submitted"
      })

    case Partage.create_recette_many(recette_params) do
      {:ok, recette} ->
        {:noreply,
         socket
         |> put_flash(:info, "Recette soumise pour validation")
         |> push_navigate(to: return_path(socket.assigns.return_to, recette))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _recette), do: ~p"/recettes"
  defp return_path("show", recette), do: ~p"/recettes/#{recette}"
end
