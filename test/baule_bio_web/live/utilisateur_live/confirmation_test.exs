defmodule BauleBioWeb.UtilisateurLive.ConfirmationTest do
  use BauleBioWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import BauleBio.CompteFixtures

  alias BauleBio.Compte

  setup do
    %{unconfirmed_utilisateur: unconfirmed_utilisateur_fixture(), confirmed_utilisateur: utilisateur_fixture()}
  end

  describe "Confirm utilisateur" do
    test "renders confirmation page for unconfirmed utilisateur", %{conn: conn, unconfirmed_utilisateur: utilisateur} do
      token =
        extract_utilisateur_token(fn url ->
          Compte.deliver_login_instructions(utilisateur, url)
        end)

      {:ok, _lv, html} = live(conn, ~p"/utilisateurs/log-in/#{token}")
      assert html =~ "Confirm and stay logged in"
    end

    test "renders login page for confirmed utilisateur", %{conn: conn, confirmed_utilisateur: utilisateur} do
      token =
        extract_utilisateur_token(fn url ->
          Compte.deliver_login_instructions(utilisateur, url)
        end)

      {:ok, _lv, html} = live(conn, ~p"/utilisateurs/log-in/#{token}")
      refute html =~ "Confirm my account"
      assert html =~ "Log in"
    end

    test "confirms the given token once", %{conn: conn, unconfirmed_utilisateur: utilisateur} do
      token =
        extract_utilisateur_token(fn url ->
          Compte.deliver_login_instructions(utilisateur, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/utilisateurs/log-in/#{token}")

      form = form(lv, "#confirmation_form", %{"utilisateur" => %{"token" => token}})
      render_submit(form)

      conn = follow_trigger_action(form, conn)

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Utilisateur confirmed successfully"

      assert Compte.get_utilisateur!(utilisateur.id).confirmed_at
      # we are logged in now
      assert get_session(conn, :utilisateur_token)
      assert redirected_to(conn) == ~p"/"

      # log out, new conn
      conn = build_conn()

      {:ok, _lv, html} =
        live(conn, ~p"/utilisateurs/log-in/#{token}")
        |> follow_redirect(conn, ~p"/utilisateurs/log-in")

      assert html =~ "Magic link is invalid or it has expired"
    end

    test "logs confirmed utilisateur in without changing confirmed_at", %{
      conn: conn,
      confirmed_utilisateur: utilisateur
    } do
      token =
        extract_utilisateur_token(fn url ->
          Compte.deliver_login_instructions(utilisateur, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/utilisateurs/log-in/#{token}")

      form = form(lv, "#login_form", %{"utilisateur" => %{"token" => token}})
      render_submit(form)

      conn = follow_trigger_action(form, conn)

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Welcome back!"

      assert Compte.get_utilisateur!(utilisateur.id).confirmed_at == utilisateur.confirmed_at

      # log out, new conn
      conn = build_conn()

      {:ok, _lv, html} =
        live(conn, ~p"/utilisateurs/log-in/#{token}")
        |> follow_redirect(conn, ~p"/utilisateurs/log-in")

      assert html =~ "Magic link is invalid or it has expired"
    end

    test "raises error for invalid token", %{conn: conn} do
      {:ok, _lv, html} =
        live(conn, ~p"/utilisateurs/log-in/invalid-token")
        |> follow_redirect(conn, ~p"/utilisateurs/log-in")

      assert html =~ "Magic link is invalid or it has expired"
    end
  end
end
