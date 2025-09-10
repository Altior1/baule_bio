defmodule BauleBioWeb.UtilisateurAuthTest do
  use BauleBioWeb.ConnCase, async: true

  alias Phoenix.LiveView
  alias BauleBio.Compte
  alias BauleBio.Compte.Scope
  alias BauleBioWeb.UtilisateurAuth

  import BauleBio.CompteFixtures

  @remember_me_cookie "_baule_bio_web_utilisateur_remember_me"
  @remember_me_cookie_max_age 60 * 60 * 24 * 14

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, BauleBioWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{utilisateur: %{utilisateur_fixture() | authenticated_at: DateTime.utc_now(:second)}, conn: conn}
  end

  describe "log_in_utilisateur/3" do
    test "stores the utilisateur token in the session", %{conn: conn, utilisateur: utilisateur} do
      conn = UtilisateurAuth.log_in_utilisateur(conn, utilisateur)
      assert token = get_session(conn, :utilisateur_token)
      assert get_session(conn, :live_socket_id) == "utilisateurs_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == ~p"/"
      assert Compte.get_utilisateur_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, utilisateur: utilisateur} do
      conn = conn |> put_session(:to_be_removed, "value") |> UtilisateurAuth.log_in_utilisateur(utilisateur)
      refute get_session(conn, :to_be_removed)
    end

    test "keeps session when re-authenticating", %{conn: conn, utilisateur: utilisateur} do
      conn =
        conn
        |> assign(:current_scope, Scope.for_utilisateur(utilisateur))
        |> put_session(:to_be_removed, "value")
        |> UtilisateurAuth.log_in_utilisateur(utilisateur)

      assert get_session(conn, :to_be_removed)
    end

    test "clears session when utilisateur does not match when re-authenticating", %{
      conn: conn,
      utilisateur: utilisateur
    } do
      other_utilisateur = utilisateur_fixture()

      conn =
        conn
        |> assign(:current_scope, Scope.for_utilisateur(other_utilisateur))
        |> put_session(:to_be_removed, "value")
        |> UtilisateurAuth.log_in_utilisateur(utilisateur)

      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, utilisateur: utilisateur} do
      conn = conn |> put_session(:utilisateur_return_to, "/hello") |> UtilisateurAuth.log_in_utilisateur(utilisateur)
      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, utilisateur: utilisateur} do
      conn = conn |> fetch_cookies() |> UtilisateurAuth.log_in_utilisateur(utilisateur, %{"remember_me" => "true"})
      assert get_session(conn, :utilisateur_token) == conn.cookies[@remember_me_cookie]
      assert get_session(conn, :utilisateur_remember_me) == true

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :utilisateur_token)
      assert max_age == @remember_me_cookie_max_age
    end

    test "redirects to settings when utilisateur is already logged in", %{conn: conn, utilisateur: utilisateur} do
      conn =
        conn
        |> assign(:current_scope, Scope.for_utilisateur(utilisateur))
        |> UtilisateurAuth.log_in_utilisateur(utilisateur)

      assert redirected_to(conn) == ~p"/utilisateurs/settings"
    end

    test "writes a cookie if remember_me was set in previous session", %{conn: conn, utilisateur: utilisateur} do
      conn = conn |> fetch_cookies() |> UtilisateurAuth.log_in_utilisateur(utilisateur, %{"remember_me" => "true"})
      assert get_session(conn, :utilisateur_token) == conn.cookies[@remember_me_cookie]
      assert get_session(conn, :utilisateur_remember_me) == true

      conn =
        conn
        |> recycle()
        |> Map.replace!(:secret_key_base, BauleBioWeb.Endpoint.config(:secret_key_base))
        |> fetch_cookies()
        |> init_test_session(%{utilisateur_remember_me: true})

      # the conn is already logged in and has the remember_me cookie set,
      # now we log in again and even without explicitly setting remember_me,
      # the cookie should be set again
      conn = conn |> UtilisateurAuth.log_in_utilisateur(utilisateur, %{})
      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :utilisateur_token)
      assert max_age == @remember_me_cookie_max_age
      assert get_session(conn, :utilisateur_remember_me) == true
    end
  end

  describe "logout_utilisateur/1" do
    test "erases session and cookies", %{conn: conn, utilisateur: utilisateur} do
      utilisateur_token = Compte.generate_utilisateur_session_token(utilisateur)

      conn =
        conn
        |> put_session(:utilisateur_token, utilisateur_token)
        |> put_req_cookie(@remember_me_cookie, utilisateur_token)
        |> fetch_cookies()
        |> UtilisateurAuth.log_out_utilisateur()

      refute get_session(conn, :utilisateur_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
      refute Compte.get_utilisateur_by_session_token(utilisateur_token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "utilisateurs_sessions:abcdef-token"
      BauleBioWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> UtilisateurAuth.log_out_utilisateur()

      assert_receive %Phoenix.Socket.Broadcast{event: "disconnect", topic: ^live_socket_id}
    end

    test "works even if utilisateur is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> UtilisateurAuth.log_out_utilisateur()
      refute get_session(conn, :utilisateur_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
    end
  end

  describe "fetch_current_scope_for_utilisateur/2" do
    test "authenticates utilisateur from session", %{conn: conn, utilisateur: utilisateur} do
      utilisateur_token = Compte.generate_utilisateur_session_token(utilisateur)

      conn =
        conn |> put_session(:utilisateur_token, utilisateur_token) |> UtilisateurAuth.fetch_current_scope_for_utilisateur([])

      assert conn.assigns.current_scope.utilisateur.id == utilisateur.id
      assert conn.assigns.current_scope.utilisateur.authenticated_at == utilisateur.authenticated_at
      assert get_session(conn, :utilisateur_token) == utilisateur_token
    end

    test "authenticates utilisateur from cookies", %{conn: conn, utilisateur: utilisateur} do
      logged_in_conn =
        conn |> fetch_cookies() |> UtilisateurAuth.log_in_utilisateur(utilisateur, %{"remember_me" => "true"})

      utilisateur_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> UtilisateurAuth.fetch_current_scope_for_utilisateur([])

      assert conn.assigns.current_scope.utilisateur.id == utilisateur.id
      assert conn.assigns.current_scope.utilisateur.authenticated_at == utilisateur.authenticated_at
      assert get_session(conn, :utilisateur_token) == utilisateur_token
      assert get_session(conn, :utilisateur_remember_me)

      assert get_session(conn, :live_socket_id) ==
               "utilisateurs_sessions:#{Base.url_encode64(utilisateur_token)}"
    end

    test "does not authenticate if data is missing", %{conn: conn, utilisateur: utilisateur} do
      _ = Compte.generate_utilisateur_session_token(utilisateur)
      conn = UtilisateurAuth.fetch_current_scope_for_utilisateur(conn, [])
      refute get_session(conn, :utilisateur_token)
      refute conn.assigns.current_scope
    end

    test "reissues a new token after a few days and refreshes cookie", %{conn: conn, utilisateur: utilisateur} do
      logged_in_conn =
        conn |> fetch_cookies() |> UtilisateurAuth.log_in_utilisateur(utilisateur, %{"remember_me" => "true"})

      token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      offset_utilisateur_token(token, -10, :day)
      {utilisateur, _} = Compte.get_utilisateur_by_session_token(token)

      conn =
        conn
        |> put_session(:utilisateur_token, token)
        |> put_session(:utilisateur_remember_me, true)
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> UtilisateurAuth.fetch_current_scope_for_utilisateur([])

      assert conn.assigns.current_scope.utilisateur.id == utilisateur.id
      assert conn.assigns.current_scope.utilisateur.authenticated_at == utilisateur.authenticated_at
      assert new_token = get_session(conn, :utilisateur_token)
      assert new_token != token
      assert %{value: new_signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert new_signed_token != signed_token
      assert max_age == @remember_me_cookie_max_age
    end
  end

  describe "on_mount :mount_current_scope" do
    setup %{conn: conn} do
      %{conn: UtilisateurAuth.fetch_current_scope_for_utilisateur(conn, [])}
    end

    test "assigns current_scope based on a valid utilisateur_token", %{conn: conn, utilisateur: utilisateur} do
      utilisateur_token = Compte.generate_utilisateur_session_token(utilisateur)
      session = conn |> put_session(:utilisateur_token, utilisateur_token) |> get_session()

      {:cont, updated_socket} =
        UtilisateurAuth.on_mount(:mount_current_scope, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_scope.utilisateur.id == utilisateur.id
    end

    test "assigns nil to current_scope assign if there isn't a valid utilisateur_token", %{conn: conn} do
      utilisateur_token = "invalid_token"
      session = conn |> put_session(:utilisateur_token, utilisateur_token) |> get_session()

      {:cont, updated_socket} =
        UtilisateurAuth.on_mount(:mount_current_scope, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_scope == nil
    end

    test "assigns nil to current_scope assign if there isn't a utilisateur_token", %{conn: conn} do
      session = conn |> get_session()

      {:cont, updated_socket} =
        UtilisateurAuth.on_mount(:mount_current_scope, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_scope == nil
    end
  end

  describe "on_mount :require_authenticated" do
    test "authenticates current_scope based on a valid utilisateur_token", %{conn: conn, utilisateur: utilisateur} do
      utilisateur_token = Compte.generate_utilisateur_session_token(utilisateur)
      session = conn |> put_session(:utilisateur_token, utilisateur_token) |> get_session()

      {:cont, updated_socket} =
        UtilisateurAuth.on_mount(:require_authenticated, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_scope.utilisateur.id == utilisateur.id
    end

    test "redirects to login page if there isn't a valid utilisateur_token", %{conn: conn} do
      utilisateur_token = "invalid_token"
      session = conn |> put_session(:utilisateur_token, utilisateur_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: BauleBioWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = UtilisateurAuth.on_mount(:require_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_scope == nil
    end

    test "redirects to login page if there isn't a utilisateur_token", %{conn: conn} do
      session = conn |> get_session()

      socket = %LiveView.Socket{
        endpoint: BauleBioWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = UtilisateurAuth.on_mount(:require_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_scope == nil
    end
  end

  describe "on_mount :require_sudo_mode" do
    test "allows utilisateurs that have authenticated in the last 10 minutes", %{conn: conn, utilisateur: utilisateur} do
      utilisateur_token = Compte.generate_utilisateur_session_token(utilisateur)
      session = conn |> put_session(:utilisateur_token, utilisateur_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: BauleBioWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      assert {:cont, _updated_socket} =
               UtilisateurAuth.on_mount(:require_sudo_mode, %{}, session, socket)
    end

    test "redirects when authentication is too old", %{conn: conn, utilisateur: utilisateur} do
      eleven_minutes_ago = DateTime.utc_now(:second) |> DateTime.add(-11, :minute)
      utilisateur = %{utilisateur | authenticated_at: eleven_minutes_ago}
      utilisateur_token = Compte.generate_utilisateur_session_token(utilisateur)
      {utilisateur, token_inserted_at} = Compte.get_utilisateur_by_session_token(utilisateur_token)
      assert DateTime.compare(token_inserted_at, utilisateur.authenticated_at) == :gt
      session = conn |> put_session(:utilisateur_token, utilisateur_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: BauleBioWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      assert {:halt, _updated_socket} =
               UtilisateurAuth.on_mount(:require_sudo_mode, %{}, session, socket)
    end
  end

  describe "require_authenticated_utilisateur/2" do
    setup %{conn: conn} do
      %{conn: UtilisateurAuth.fetch_current_scope_for_utilisateur(conn, [])}
    end

    test "redirects if utilisateur is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> UtilisateurAuth.require_authenticated_utilisateur([])
      assert conn.halted

      assert redirected_to(conn) == ~p"/utilisateurs/log-in"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must log in to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | path_info: ["foo"], query_string: ""}
        |> fetch_flash()
        |> UtilisateurAuth.require_authenticated_utilisateur([])

      assert halted_conn.halted
      assert get_session(halted_conn, :utilisateur_return_to) == "/foo"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar=baz"}
        |> fetch_flash()
        |> UtilisateurAuth.require_authenticated_utilisateur([])

      assert halted_conn.halted
      assert get_session(halted_conn, :utilisateur_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar", method: "POST"}
        |> fetch_flash()
        |> UtilisateurAuth.require_authenticated_utilisateur([])

      assert halted_conn.halted
      refute get_session(halted_conn, :utilisateur_return_to)
    end

    test "does not redirect if utilisateur is authenticated", %{conn: conn, utilisateur: utilisateur} do
      conn =
        conn
        |> assign(:current_scope, Scope.for_utilisateur(utilisateur))
        |> UtilisateurAuth.require_authenticated_utilisateur([])

      refute conn.halted
      refute conn.status
    end
  end

  describe "disconnect_sessions/1" do
    test "broadcasts disconnect messages for each token" do
      tokens = [%{token: "token1"}, %{token: "token2"}]

      for %{token: token} <- tokens do
        BauleBioWeb.Endpoint.subscribe("utilisateurs_sessions:#{Base.url_encode64(token)}")
      end

      UtilisateurAuth.disconnect_sessions(tokens)

      assert_receive %Phoenix.Socket.Broadcast{
        event: "disconnect",
        topic: "utilisateurs_sessions:dG9rZW4x"
      }

      assert_receive %Phoenix.Socket.Broadcast{
        event: "disconnect",
        topic: "utilisateurs_sessions:dG9rZW4y"
      }
    end
  end
end
