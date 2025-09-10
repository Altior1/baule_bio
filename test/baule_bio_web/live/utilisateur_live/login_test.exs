defmodule BauleBioWeb.UtilisateurLive.LoginTest do
  use BauleBioWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import BauleBio.CompteFixtures

  describe "login page" do
    test "renders login page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/utilisateurs/log-in")

      assert html =~ "Log in"
      assert html =~ "Register"
      assert html =~ "Log in with email"
    end
  end

  describe "utilisateur login - magic link" do
    test "sends magic link email when utilisateur exists", %{conn: conn} do
      utilisateur = utilisateur_fixture()

      {:ok, lv, _html} = live(conn, ~p"/utilisateurs/log-in")

      {:ok, _lv, html} =
        form(lv, "#login_form_magic", utilisateur: %{email: utilisateur.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/utilisateurs/log-in")

      assert html =~ "If your email is in our system"

      assert BauleBio.Repo.get_by!(BauleBio.Compte.UtilisateurToken, utilisateur_id: utilisateur.id).context ==
               "login"
    end

    test "does not disclose if utilisateur is registered", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/utilisateurs/log-in")

      {:ok, _lv, html} =
        form(lv, "#login_form_magic", utilisateur: %{email: "idonotexist@example.com"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/utilisateurs/log-in")

      assert html =~ "If your email is in our system"
    end
  end

  describe "utilisateur login - password" do
    test "redirects if utilisateur logs in with valid credentials", %{conn: conn} do
      utilisateur = utilisateur_fixture() |> set_password()

      {:ok, lv, _html} = live(conn, ~p"/utilisateurs/log-in")

      form =
        form(lv, "#login_form_password",
          utilisateur: %{email: utilisateur.email, password: valid_utilisateur_password(), remember_me: true}
        )

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/"
    end

    test "redirects to login page with a flash error if credentials are invalid", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/utilisateurs/log-in")

      form =
        form(lv, "#login_form_password", utilisateur: %{email: "test@email.com", password: "123456"})

      render_submit(form, %{user: %{remember_me: true}})

      conn = follow_trigger_action(form, conn)
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/utilisateurs/log-in"
    end
  end

  describe "login navigation" do
    test "redirects to registration page when the Register button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/utilisateurs/log-in")

      {:ok, _login_live, login_html} =
        lv
        |> element("main a", "Sign up")
        |> render_click()
        |> follow_redirect(conn, ~p"/utilisateurs/register")

      assert login_html =~ "Register"
    end
  end

  describe "re-authentication (sudo mode)" do
    setup %{conn: conn} do
      utilisateur = utilisateur_fixture()
      %{utilisateur: utilisateur, conn: log_in_utilisateur(conn, utilisateur)}
    end

    test "shows login page with email filled in", %{conn: conn, utilisateur: utilisateur} do
      {:ok, _lv, html} = live(conn, ~p"/utilisateurs/log-in")

      assert html =~ "You need to reauthenticate"
      refute html =~ "Register"
      assert html =~ "Log in with email"

      assert html =~
               ~s(<input type="email" name="utilisateur[email]" id="login_form_magic_email" value="#{utilisateur.email}")
    end
  end
end
