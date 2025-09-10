defmodule BauleBio.Compte do
  @moduledoc """
  The Compte context.
  """

  import Ecto.Query, warn: false
  alias BauleBio.Repo

  alias BauleBio.Compte.{Utilisateur, UtilisateurToken, UtilisateurNotifier}

  ## Database getters

  @doc """
  Gets a utilisateur by email.

  ## Examples

      iex> get_utilisateur_by_email("foo@example.com")
      %Utilisateur{}

      iex> get_utilisateur_by_email("unknown@example.com")
      nil

  """
  def get_utilisateur_by_email(email) when is_binary(email) do
    Repo.get_by(Utilisateur, email: email)
  end

  @doc """
  Gets a utilisateur by email and password.

  ## Examples

      iex> get_utilisateur_by_email_and_password("foo@example.com", "correct_password")
      %Utilisateur{}

      iex> get_utilisateur_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_utilisateur_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    utilisateur = Repo.get_by(Utilisateur, email: email)
    if Utilisateur.valid_password?(utilisateur, password), do: utilisateur
  end

  @doc """
  Gets a single utilisateur.

  Raises `Ecto.NoResultsError` if the Utilisateur does not exist.

  ## Examples

      iex> get_utilisateur!(123)
      %Utilisateur{}

      iex> get_utilisateur!(456)
      ** (Ecto.NoResultsError)

  """
  def get_utilisateur!(id), do: Repo.get!(Utilisateur, id)

  ## Utilisateur registration

  @doc """
  Registers a utilisateur.

  ## Examples

      iex> register_utilisateur(%{field: value})
      {:ok, %Utilisateur{}}

      iex> register_utilisateur(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_utilisateur(attrs) do
    %Utilisateur{}
    |> Utilisateur.email_changeset(attrs)
    |> Repo.insert()
  end

  ## Settings

  @doc """
  Checks whether the utilisateur is in sudo mode.

  The utilisateur is in sudo mode when the last authentication was done no further
  than 20 minutes ago. The limit can be given as second argument in minutes.
  """
  def sudo_mode?(utilisateur, minutes \\ -20)

  def sudo_mode?(%Utilisateur{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.utc_now() |> DateTime.add(minutes, :minute))
  end

  def sudo_mode?(_utilisateur, _minutes), do: false

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the utilisateur email.

  See `BauleBio.Compte.Utilisateur.email_changeset/3` for a list of supported options.

  ## Examples

      iex> change_utilisateur_email(utilisateur)
      %Ecto.Changeset{data: %Utilisateur{}}

  """
  def change_utilisateur_email(utilisateur, attrs \\ %{}, opts \\ []) do
    Utilisateur.email_changeset(utilisateur, attrs, opts)
  end

  @doc """
  Updates the utilisateur email using the given token.

  If the token matches, the utilisateur email is updated and the token is deleted.
  """
  def update_utilisateur_email(utilisateur, token) do
    context = "change:#{utilisateur.email}"

    Repo.transact(fn ->
      with {:ok, query} <- UtilisateurToken.verify_change_email_token_query(token, context),
           %UtilisateurToken{sent_to: email} <- Repo.one(query),
           {:ok, utilisateur} <- Repo.update(Utilisateur.email_changeset(utilisateur, %{email: email})),
           {_count, _result} <-
             Repo.delete_all(from(UtilisateurToken, where: [utilisateur_id: ^utilisateur.id, context: ^context])) do
        {:ok, utilisateur}
      else
        _ -> {:error, :transaction_aborted}
      end
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the utilisateur password.

  See `BauleBio.Compte.Utilisateur.password_changeset/3` for a list of supported options.

  ## Examples

      iex> change_utilisateur_password(utilisateur)
      %Ecto.Changeset{data: %Utilisateur{}}

  """
  def change_utilisateur_password(utilisateur, attrs \\ %{}, opts \\ []) do
    Utilisateur.password_changeset(utilisateur, attrs, opts)
  end

  @doc """
  Updates the utilisateur password.

  Returns a tuple with the updated utilisateur, as well as a list of expired tokens.

  ## Examples

      iex> update_utilisateur_password(utilisateur, %{password: ...})
      {:ok, {%Utilisateur{}, [...]}}

      iex> update_utilisateur_password(utilisateur, %{password: "too short"})
      {:error, %Ecto.Changeset{}}

  """
  def update_utilisateur_password(utilisateur, attrs) do
    utilisateur
    |> Utilisateur.password_changeset(attrs)
    |> update_utilisateur_and_delete_all_tokens()
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_utilisateur_session_token(utilisateur) do
    {token, utilisateur_token} = UtilisateurToken.build_session_token(utilisateur)
    Repo.insert!(utilisateur_token)
    token
  end

  @doc """
  Gets the utilisateur with the given signed token.

  If the token is valid `{utilisateur, token_inserted_at}` is returned, otherwise `nil` is returned.
  """
  def get_utilisateur_by_session_token(token) do
    {:ok, query} = UtilisateurToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Gets the utilisateur with the given magic link token.
  """
  def get_utilisateur_by_magic_link_token(token) do
    with {:ok, query} <- UtilisateurToken.verify_magic_link_token_query(token),
         {utilisateur, _token} <- Repo.one(query) do
      utilisateur
    else
      _ -> nil
    end
  end

  @doc """
  Logs the utilisateur in by magic link.

  There are three cases to consider:

  1. The utilisateur has already confirmed their email. They are logged in
     and the magic link is expired.

  2. The utilisateur has not confirmed their email and no password is set.
     In this case, the utilisateur gets confirmed, logged in, and all tokens -
     including session ones - are expired. In theory, no other tokens
     exist but we delete all of them for best security practices.

  3. The utilisateur has not confirmed their email but a password is set.
     This cannot happen in the default implementation but may be the
     source of security pitfalls. See the "Mixing magic link and password registration" section of
     `mix help phx.gen.auth`.
  """
  def login_utilisateur_by_magic_link(token) do
    {:ok, query} = UtilisateurToken.verify_magic_link_token_query(token)

    case Repo.one(query) do
      # Prevent session fixation attacks by disallowing magic links for unconfirmed users with password
      {%Utilisateur{confirmed_at: nil, hashed_password: hash}, _token} when not is_nil(hash) ->
        raise """
        magic link log in is not allowed for unconfirmed users with a password set!

        This cannot happen with the default implementation, which indicates that you
        might have adapted the code to a different use case. Please make sure to read the
        "Mixing magic link and password registration" section of `mix help phx.gen.auth`.
        """

      {%Utilisateur{confirmed_at: nil} = utilisateur, _token} ->
        utilisateur
        |> Utilisateur.confirm_changeset()
        |> update_utilisateur_and_delete_all_tokens()

      {utilisateur, token} ->
        Repo.delete!(token)
        {:ok, {utilisateur, []}}

      nil ->
        {:error, :not_found}
    end
  end

  @doc ~S"""
  Delivers the update email instructions to the given utilisateur.

  ## Examples

      iex> deliver_utilisateur_update_email_instructions(utilisateur, current_email, &url(~p"/utilisateurs/settings/confirm-email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_utilisateur_update_email_instructions(%Utilisateur{} = utilisateur, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, utilisateur_token} = UtilisateurToken.build_email_token(utilisateur, "change:#{current_email}")

    Repo.insert!(utilisateur_token)
    UtilisateurNotifier.deliver_update_email_instructions(utilisateur, update_email_url_fun.(encoded_token))
  end

  @doc """
  Delivers the magic link login instructions to the given utilisateur.
  """
  def deliver_login_instructions(%Utilisateur{} = utilisateur, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    {encoded_token, utilisateur_token} = UtilisateurToken.build_email_token(utilisateur, "login")
    Repo.insert!(utilisateur_token)
    UtilisateurNotifier.deliver_login_instructions(utilisateur, magic_link_url_fun.(encoded_token))
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_utilisateur_session_token(token) do
    Repo.delete_all(from(UtilisateurToken, where: [token: ^token, context: "session"]))
    :ok
  end

  ## Token helper

  defp update_utilisateur_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, utilisateur} <- Repo.update(changeset) do
        tokens_to_expire = Repo.all_by(UtilisateurToken, utilisateur_id: utilisateur.id)

        Repo.delete_all(from(t in UtilisateurToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id)))

        {:ok, {utilisateur, tokens_to_expire}}
      end
    end)
  end
end
