defmodule BauleBioWeb.UtilisateurAuth do
  use BauleBioWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias BauleBio.Compte
  alias BauleBio.Compte.Scope

  # Make the remember me cookie valid for 14 days. This should match
  # the session validity setting in UtilisateurToken.
  @max_cookie_age_in_days 14
  @remember_me_cookie "_baule_bio_web_utilisateur_remember_me"
  @remember_me_options [
    sign: true,
    max_age: @max_cookie_age_in_days * 24 * 60 * 60,
    same_site: "Lax"
  ]

  # How old the session token should be before a new one is issued. When a request is made
  # with a session token older than this value, then a new session token will be created
  # and the session and remember-me cookies (if set) will be updated with the new token.
  # Lowering this value will result in more tokens being created by active users. Increasing
  # it will result in less time before a session token expires for a user to get issued a new
  # token. This can be set to a value greater than `@max_cookie_age_in_days` to disable
  # the reissuing of tokens completely.
  @session_reissue_age_in_days 7

  @doc """
  Logs the utilisateur in.

  Redirects to the session's `:utilisateur_return_to` path
  or falls back to the `signed_in_path/1`.
  """
  def log_in_utilisateur(conn, utilisateur, params \\ %{}) do
    utilisateur_return_to = get_session(conn, :utilisateur_return_to)

    conn
    |> create_or_extend_session(utilisateur, params)
    |> redirect(to: utilisateur_return_to || signed_in_path(conn))
  end

  @doc """
  Logs the utilisateur out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_utilisateur(conn) do
    utilisateur_token = get_session(conn, :utilisateur_token)
    utilisateur_token && Compte.delete_utilisateur_session_token(utilisateur_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      BauleBioWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session(nil)
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: ~p"/")
  end

  @doc """
  Authenticates the utilisateur by looking into the session and remember me token.

  Will reissue the session token if it is older than the configured age.
  """
  def fetch_current_scope_for_utilisateur(conn, _opts) do
    with {token, conn} <- ensure_utilisateur_token(conn),
         {utilisateur, token_inserted_at} <- Compte.get_utilisateur_by_session_token(token) do
      conn
      |> assign(:current_scope, Scope.for_utilisateur(utilisateur))
      |> maybe_reissue_utilisateur_session_token(utilisateur, token_inserted_at)
    else
      nil -> assign(conn, :current_scope, Scope.for_utilisateur(nil))
    end
  end

  defp ensure_utilisateur_token(conn) do
    if token = get_session(conn, :utilisateur_token) do
      {token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if token = conn.cookies[@remember_me_cookie] do
        {token, conn |> put_token_in_session(token) |> put_session(:utilisateur_remember_me, true)}
      else
        nil
      end
    end
  end

  # Reissue the session token if it is older than the configured reissue age.
  defp maybe_reissue_utilisateur_session_token(conn, utilisateur, token_inserted_at) do
    token_age = DateTime.diff(DateTime.utc_now(:second), token_inserted_at, :day)

    if token_age >= @session_reissue_age_in_days do
      create_or_extend_session(conn, utilisateur, %{})
    else
      conn
    end
  end

  # This function is the one responsible for creating session tokens
  # and storing them safely in the session and cookies. It may be called
  # either when logging in, during sudo mode, or to renew a session which
  # will soon expire.
  #
  # When the session is created, rather than extended, the renew_session
  # function will clear the session to avoid fixation attacks. See the
  # renew_session function to customize this behaviour.
  defp create_or_extend_session(conn, utilisateur, params) do
    token = Compte.generate_utilisateur_session_token(utilisateur)
    remember_me = get_session(conn, :utilisateur_remember_me)

    conn
    |> renew_session(utilisateur)
    |> put_token_in_session(token)
    |> maybe_write_remember_me_cookie(token, params, remember_me)
  end

  # Do not renew session if the utilisateur is already logged in
  # to prevent CSRF errors or data being lost in tabs that are still open
  defp renew_session(conn, utilisateur) when conn.assigns.current_scope.utilisateur.id == utilisateur.id do
    conn
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn, _utilisateur) do
  #       delete_csrf_token()
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn, _utilisateur) do
    delete_csrf_token()

    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}, _),
    do: write_remember_me_cookie(conn, token)

  defp maybe_write_remember_me_cookie(conn, token, _params, true),
    do: write_remember_me_cookie(conn, token)

  defp maybe_write_remember_me_cookie(conn, _token, _params, _), do: conn

  defp write_remember_me_cookie(conn, token) do
    conn
    |> put_session(:utilisateur_remember_me, true)
    |> put_resp_cookie(@remember_me_cookie, token, @remember_me_options)
  end

  defp put_token_in_session(conn, token) do
    conn
    |> put_session(:utilisateur_token, token)
    |> put_session(:live_socket_id, utilisateur_session_topic(token))
  end

  @doc """
  Disconnects existing sockets for the given tokens.
  """
  def disconnect_sessions(tokens) do
    Enum.each(tokens, fn %{token: token} ->
      BauleBioWeb.Endpoint.broadcast(utilisateur_session_topic(token), "disconnect", %{})
    end)
  end

  defp utilisateur_session_topic(token), do: "utilisateurs_sessions:#{Base.url_encode64(token)}"

  @doc """
  Handles mounting and authenticating the current_scope in LiveViews.

  ## `on_mount` arguments

    * `:mount_current_scope` - Assigns current_scope
      to socket assigns based on utilisateur_token, or nil if
      there's no utilisateur_token or no matching utilisateur.

    * `:require_authenticated` - Authenticates the utilisateur from the session,
      and assigns the current_scope to socket assigns based
      on utilisateur_token.
      Redirects to login page if there's no logged utilisateur.

  ## Examples

  Use the `on_mount` lifecycle macro in LiveViews to mount or authenticate
  the `current_scope`:

      defmodule BauleBioWeb.PageLive do
        use BauleBioWeb, :live_view

        on_mount {BauleBioWeb.UtilisateurAuth, :mount_current_scope}
        ...
      end

  Or use the `live_session` of your router to invoke the on_mount callback:

      live_session :authenticated, on_mount: [{BauleBioWeb.UtilisateurAuth, :require_authenticated}] do
        live "/profile", ProfileLive, :index
      end
  """
  def on_mount(:mount_current_scope, _params, session, socket) do
    {:cont, mount_current_scope(socket, session)}
  end

  def on_mount(:require_authenticated, _params, session, socket) do
    socket = mount_current_scope(socket, session)

    if socket.assigns.current_scope && socket.assigns.current_scope.utilisateur do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must log in to access this page.")
        |> Phoenix.LiveView.redirect(to: ~p"/utilisateurs/log-in")

      {:halt, socket}
    end
  end

  def on_mount(:require_sudo_mode, _params, session, socket) do
    socket = mount_current_scope(socket, session)

    if Compte.sudo_mode?(socket.assigns.current_scope.utilisateur, -10) do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must re-authenticate to access this page.")
        |> Phoenix.LiveView.redirect(to: ~p"/utilisateurs/log-in")

      {:halt, socket}
    end
  end

  defp mount_current_scope(socket, session) do
    Phoenix.Component.assign_new(socket, :current_scope, fn ->
      {utilisateur, _} =
        if utilisateur_token = session["utilisateur_token"] do
          Compte.get_utilisateur_by_session_token(utilisateur_token)
        end || {nil, nil}

      Scope.for_utilisateur(utilisateur)
    end)
  end

  @doc "Returns the path to redirect to after log in."
  # the utilisateur was already logged in, redirect to settings
  def signed_in_path(%Plug.Conn{assigns: %{current_scope: %Scope{utilisateur: %Compte.Utilisateur{}}}}) do
    ~p"/utilisateurs/settings"
  end

  def signed_in_path(_), do: ~p"/"

  @doc """
  Plug for routes that require the utilisateur to be authenticated.
  """
  def require_authenticated_utilisateur(conn, _opts) do
    if conn.assigns.current_scope && conn.assigns.current_scope.utilisateur do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/utilisateurs/log-in")
      |> halt()
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :utilisateur_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn
end
