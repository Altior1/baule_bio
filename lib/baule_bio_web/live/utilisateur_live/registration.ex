defmodule BauleBioWeb.UtilisateurLive.Registration do
  use BauleBioWeb, :live_view

  alias BauleBio.Compte
  alias BauleBio.Compte.Utilisateur

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm">
        <div class="text-center">
          <.header>
            Register for an account
            <:subtitle>
              Already registered?
              <.link
                navigate={~p"/utilisateurs/log-in"}
                class="font-semibold text-brand hover:underline"
              >
                Log in
              </.link>
              to your account now.
            </:subtitle>
          </.header>
        </div>

        <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
          <.input
            field={@form[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            required
            phx-mounted={JS.focus()}
          />
          <.input
            field={@form[:password]}
            type="password"
            label="Password"
            autocomplete="new-password"
            required
          />

          <.button phx-disable-with="Creating account..." class="btn btn-primary w-full">
            Create an account
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{utilisateur: utilisateur}}} = socket)
      when not is_nil(utilisateur) do
    {:ok, redirect(socket, to: BauleBioWeb.UtilisateurAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = Compte.change_utilisateur_email(%Utilisateur{}, %{}, validate_unique: false)

    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"utilisateur" => utilisateur_params}, socket) do
    case Compte.register_utilisateur(utilisateur_params) do
      {:ok, utilisateur} ->
        {:ok, _} =
          Compte.deliver_login_instructions(
            utilisateur,
            &url(~p"/utilisateurs/log-in/#{&1}")
          )

        {:noreply,
         socket
         |> put_flash(
           :info,
           "An email was sent to #{utilisateur.email}, please access it to confirm your account."
         )
         |> push_navigate(to: ~p"/utilisateurs/log-in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"utilisateur" => utilisateur_params}, socket) do
    changeset =
      Compte.change_utilisateur_email(%Utilisateur{}, utilisateur_params, validate_unique: false)

    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "utilisateur")
    assign(socket, form: form)
  end
end
