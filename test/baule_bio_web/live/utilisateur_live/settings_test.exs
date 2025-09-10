defmodule BauleBioWeb.UtilisateurLive.SettingsTest do
  use BauleBioWeb.ConnCase, async: true

  alias BauleBio.Compte
  import Phoenix.LiveViewTest
  import BauleBio.CompteFixtures

  describe "Settings page" do
    test "renders settings page", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_utilisateur(utilisateur_fixture())
        |> live(~p"/utilisateurs/settings")

      assert html =~ "Change Email"
      assert html =~ "Save Password"
    end

    test "redirects if utilisateur is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/utilisateurs/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/utilisateurs/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "redirects if utilisateur is not in sudo mode", %{conn: conn} do
      {:ok, conn} =
        conn
        |> log_in_utilisateur(utilisateur_fixture(),
          token_authenticated_at: DateTime.add(DateTime.utc_now(:second), -11, :minute)
        )
        |> live(~p"/utilisateurs/settings")
        |> follow_redirect(conn, ~p"/utilisateurs/log-in")

      assert conn.resp_body =~ "You must re-authenticate to access this page."
    end
  end

  describe "update email form" do
    setup %{conn: conn} do
      utilisateur = utilisateur_fixture()
      %{conn: log_in_utilisateur(conn, utilisateur), utilisateur: utilisateur}
    end

    test "updates the utilisateur email", %{conn: conn, utilisateur: utilisateur} do
      new_email = unique_utilisateur_email()

      {:ok, lv, _html} = live(conn, ~p"/utilisateurs/settings")

      result =
        lv
        |> form("#email_form", %{
          "utilisateur" => %{"email" => new_email}
        })
        |> render_submit()

      assert result =~ "A link to confirm your email"
      assert Compte.get_utilisateur_by_email(utilisateur.email)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/utilisateurs/settings")

      result =
        lv
        |> element("#email_form")
        |> render_change(%{
          "action" => "update_email",
          "utilisateur" => %{"email" => "with spaces"}
        })

      assert result =~ "Change Email"
      assert result =~ "must have the @ sign and no spaces"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn, utilisateur: utilisateur} do
      {:ok, lv, _html} = live(conn, ~p"/utilisateurs/settings")

      result =
        lv
        |> form("#email_form", %{
          "utilisateur" => %{"email" => utilisateur.email}
        })
        |> render_submit()

      assert result =~ "Change Email"
      assert result =~ "did not change"
    end
  end

  describe "update password form" do
    setup %{conn: conn} do
      utilisateur = utilisateur_fixture()
      %{conn: log_in_utilisateur(conn, utilisateur), utilisateur: utilisateur}
    end

    test "updates the utilisateur password", %{conn: conn, utilisateur: utilisateur} do
      new_password = valid_utilisateur_password()

      {:ok, lv, _html} = live(conn, ~p"/utilisateurs/settings")

      form =
        form(lv, "#password_form", %{
          "utilisateur" => %{
            "email" => utilisateur.email,
            "password" => new_password,
            "password_confirmation" => new_password
          }
        })

      render_submit(form)

      new_password_conn = follow_trigger_action(form, conn)

      assert redirected_to(new_password_conn) == ~p"/utilisateurs/settings"

      assert get_session(new_password_conn, :utilisateur_token) != get_session(conn, :utilisateur_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert Compte.get_utilisateur_by_email_and_password(utilisateur.email, new_password)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/utilisateurs/settings")

      result =
        lv
        |> element("#password_form")
        |> render_change(%{
          "utilisateur" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      assert result =~ "Save Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/utilisateurs/settings")

      result =
        lv
        |> form("#password_form", %{
          "utilisateur" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })
        |> render_submit()

      assert result =~ "Save Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
    end
  end

  describe "confirm email" do
    setup %{conn: conn} do
      utilisateur = utilisateur_fixture()
      email = unique_utilisateur_email()

      token =
        extract_utilisateur_token(fn url ->
          Compte.deliver_utilisateur_update_email_instructions(%{utilisateur | email: email}, utilisateur.email, url)
        end)

      %{conn: log_in_utilisateur(conn, utilisateur), token: token, email: email, utilisateur: utilisateur}
    end

    test "updates the utilisateur email once", %{conn: conn, utilisateur: utilisateur, token: token, email: email} do
      {:error, redirect} = live(conn, ~p"/utilisateurs/settings/confirm-email/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/utilisateurs/settings"
      assert %{"info" => message} = flash
      assert message == "Email changed successfully."
      refute Compte.get_utilisateur_by_email(utilisateur.email)
      assert Compte.get_utilisateur_by_email(email)

      # use confirm token again
      {:error, redirect} = live(conn, ~p"/utilisateurs/settings/confirm-email/#{token}")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/utilisateurs/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
    end

    test "does not update email with invalid token", %{conn: conn, utilisateur: utilisateur} do
      {:error, redirect} = live(conn, ~p"/utilisateurs/settings/confirm-email/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/utilisateurs/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
      assert Compte.get_utilisateur_by_email(utilisateur.email)
    end

    test "redirects if utilisateur is not logged in", %{token: token} do
      conn = build_conn()
      {:error, redirect} = live(conn, ~p"/utilisateurs/settings/confirm-email/#{token}")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/utilisateurs/log-in"
      assert %{"error" => message} = flash
      assert message == "You must log in to access this page."
    end
  end
end
