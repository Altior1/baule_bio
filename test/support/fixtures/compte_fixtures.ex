defmodule BauleBio.CompteFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BauleBio.Compte` context.
  """

  import Ecto.Query

  alias BauleBio.Compte
  alias BauleBio.Compte.Scope

  def unique_utilisateur_email, do: "utilisateur#{System.unique_integer()}@example.com"
  def valid_utilisateur_password, do: "hello world!"

  def valid_utilisateur_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_utilisateur_email()
    })
  end

  def unconfirmed_utilisateur_fixture(attrs \\ %{}) do
    {:ok, utilisateur} =
      attrs
      |> valid_utilisateur_attributes()
      |> Compte.register_utilisateur()

    utilisateur
  end

  def utilisateur_fixture(attrs \\ %{}) do
    utilisateur = unconfirmed_utilisateur_fixture(attrs)

    token =
      extract_utilisateur_token(fn url ->
        Compte.deliver_login_instructions(utilisateur, url)
      end)

    {:ok, {utilisateur, _expired_tokens}} =
      Compte.login_utilisateur_by_magic_link(token)

    utilisateur
  end

  def utilisateur_scope_fixture do
    utilisateur = utilisateur_fixture()
    utilisateur_scope_fixture(utilisateur)
  end

  def utilisateur_scope_fixture(utilisateur) do
    Scope.for_utilisateur(utilisateur)
  end

  def set_password(utilisateur) do
    {:ok, {utilisateur, _expired_tokens}} =
      Compte.update_utilisateur_password(utilisateur, %{password: valid_utilisateur_password()})

    utilisateur
  end

  def extract_utilisateur_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  def override_token_authenticated_at(token, authenticated_at) when is_binary(token) do
    BauleBio.Repo.update_all(
      from(t in Compte.UtilisateurToken,
        where: t.token == ^token
      ),
      set: [authenticated_at: authenticated_at]
    )
  end

  def generate_utilisateur_magic_link_token(utilisateur) do
    {encoded_token, utilisateur_token} = Compte.UtilisateurToken.build_email_token(utilisateur, "login")
    BauleBio.Repo.insert!(utilisateur_token)
    {encoded_token, utilisateur_token.token}
  end

  def offset_utilisateur_token(token, amount_to_add, unit) do
    dt = DateTime.add(DateTime.utc_now(:second), amount_to_add, unit)

    BauleBio.Repo.update_all(
      from(ut in Compte.UtilisateurToken, where: ut.token == ^token),
      set: [inserted_at: dt, authenticated_at: dt]
    )
  end
end
