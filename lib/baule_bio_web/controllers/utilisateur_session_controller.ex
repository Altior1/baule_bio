defmodule BauleBioWeb.UtilisateurSessionController do
  use BauleBioWeb, :controller

  alias BauleBio.Compte
  alias BauleBioWeb.UtilisateurAuth

  def create(conn, %{"_action" => "confirmed"} = params) do
    create(conn, params, "Utilisateur confirmed successfully.")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  # magic link login
  defp create(conn, %{"utilisateur" => %{"token" => token} = utilisateur_params}, info) do
    case Compte.login_utilisateur_by_magic_link(token) do
      {:ok, {utilisateur, tokens_to_disconnect}} ->
        UtilisateurAuth.disconnect_sessions(tokens_to_disconnect)

        conn
        |> put_flash(:info, info)
        |> UtilisateurAuth.log_in_utilisateur(utilisateur, utilisateur_params)

      _ ->
        conn
        |> put_flash(:error, "The link is invalid or it has expired.")
        |> redirect(to: ~p"/utilisateurs/log-in")
    end
  end

  # email + password login
  defp create(conn, %{"utilisateur" => utilisateur_params}, info) do
    %{"email" => email, "password" => password} = utilisateur_params

    if utilisateur = Compte.get_utilisateur_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> UtilisateurAuth.log_in_utilisateur(utilisateur, utilisateur_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/utilisateurs/log-in")
    end
  end

  def update_password(conn, %{"utilisateur" => utilisateur_params} = params) do
    utilisateur = conn.assigns.current_scope.utilisateur
    true = Compte.sudo_mode?(utilisateur)
    {:ok, {_utilisateur, expired_tokens}} = Compte.update_utilisateur_password(utilisateur, utilisateur_params)

    # disconnect all existing LiveViews with old sessions
    UtilisateurAuth.disconnect_sessions(expired_tokens)

    conn
    |> put_session(:utilisateur_return_to, ~p"/utilisateurs/settings")
    |> create(params, "Password updated successfully!")
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UtilisateurAuth.log_out_utilisateur()
  end
end
