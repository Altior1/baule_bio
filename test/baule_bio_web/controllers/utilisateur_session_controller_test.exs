defmodule BauleBioWeb.UtilisateurSessionControllerTest do
  use BauleBioWeb.ConnCase, async: true

  import BauleBio.CompteFixtures
  alias BauleBio.Compte

  setup do
    %{unconfirmed_utilisateur: unconfirmed_utilisateur_fixture(), utilisateur: utilisateur_fixture()}
  end

  describe "POST /utilisateurs/log-in - email and password" do
    test "logs the utilisateur in", %{conn: conn, utilisateur: utilisateur} do
      utilisateur = set_password(utilisateur)

      conn =
        post(conn, ~p"/utilisateurs/log-in", %{
          "utilisateur" => %{"email" => utilisateur.email, "password" => valid_utilisateur_password()}
        })

      assert get_session(conn, :utilisateur_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ utilisateur.email
      assert response =~ ~p"/utilisateurs/settings"
      assert response =~ ~p"/utilisateurs/log-out"
    end

    test "logs the utilisateur in with remember me", %{conn: conn, utilisateur: utilisateur} do
      utilisateur = set_password(utilisateur)

      conn =
        post(conn, ~p"/utilisateurs/log-in", %{
          "utilisateur" => %{
            "email" => utilisateur.email,
            "password" => valid_utilisateur_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_baule_bio_web_utilisateur_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "logs the utilisateur in with return to", %{conn: conn, utilisateur: utilisateur} do
      utilisateur = set_password(utilisateur)

      conn =
        conn
        |> init_test_session(utilisateur_return_to: "/foo/bar")
        |> post(~p"/utilisateurs/log-in", %{
          "utilisateur" => %{
            "email" => utilisateur.email,
            "password" => valid_utilisateur_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "redirects to login page with invalid credentials", %{conn: conn, utilisateur: utilisateur} do
      conn =
        post(conn, ~p"/utilisateurs/log-in?mode=password", %{
          "utilisateur" => %{"email" => utilisateur.email, "password" => "invalid_password"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/utilisateurs/log-in"
    end
  end

  describe "POST /utilisateurs/log-in - magic link" do
    test "logs the utilisateur in", %{conn: conn, utilisateur: utilisateur} do
      {token, _hashed_token} = generate_utilisateur_magic_link_token(utilisateur)

      conn =
        post(conn, ~p"/utilisateurs/log-in", %{
          "utilisateur" => %{"token" => token}
        })

      assert get_session(conn, :utilisateur_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ utilisateur.email
      assert response =~ ~p"/utilisateurs/settings"
      assert response =~ ~p"/utilisateurs/log-out"
    end

    test "confirms unconfirmed utilisateur", %{conn: conn, unconfirmed_utilisateur: utilisateur} do
      {token, _hashed_token} = generate_utilisateur_magic_link_token(utilisateur)
      refute utilisateur.confirmed_at

      conn =
        post(conn, ~p"/utilisateurs/log-in", %{
          "utilisateur" => %{"token" => token},
          "_action" => "confirmed"
        })

      assert get_session(conn, :utilisateur_token)
      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Utilisateur confirmed successfully."

      assert Compte.get_utilisateur!(utilisateur.id).confirmed_at

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ utilisateur.email
      assert response =~ ~p"/utilisateurs/settings"
      assert response =~ ~p"/utilisateurs/log-out"
    end

    test "redirects to login page when magic link is invalid", %{conn: conn} do
      conn =
        post(conn, ~p"/utilisateurs/log-in", %{
          "utilisateur" => %{"token" => "invalid"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "The link is invalid or it has expired."

      assert redirected_to(conn) == ~p"/utilisateurs/log-in"
    end
  end

  describe "DELETE /utilisateurs/log-out" do
    test "logs the utilisateur out", %{conn: conn, utilisateur: utilisateur} do
      conn = conn |> log_in_utilisateur(utilisateur) |> delete(~p"/utilisateurs/log-out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :utilisateur_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the utilisateur is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/utilisateurs/log-out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :utilisateur_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
