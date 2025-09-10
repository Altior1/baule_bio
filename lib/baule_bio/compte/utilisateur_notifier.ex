defmodule BauleBio.Compte.UtilisateurNotifier do
  import Swoosh.Email

  alias BauleBio.Mailer
  alias BauleBio.Compte.Utilisateur

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"BauleBio", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to update a utilisateur email.
  """
  def deliver_update_email_instructions(utilisateur, url) do
    deliver(utilisateur.email, "Update email instructions", """

    ==============================

    Hi #{utilisateur.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to log in with a magic link.
  """
  def deliver_login_instructions(utilisateur, url) do
    case utilisateur do
      %Utilisateur{confirmed_at: nil} -> deliver_confirmation_instructions(utilisateur, url)
      _ -> deliver_magic_link_instructions(utilisateur, url)
    end
  end

  defp deliver_magic_link_instructions(utilisateur, url) do
    deliver(utilisateur.email, "Log in instructions", """

    ==============================

    Hi #{utilisateur.email},

    You can log into your account by visiting the URL below:

    #{url}

    If you didn't request this email, please ignore this.

    ==============================
    """)
  end

  defp deliver_confirmation_instructions(utilisateur, url) do
    deliver(utilisateur.email, "Confirmation instructions", """

    ==============================

    Hi #{utilisateur.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end
end
