defmodule BauleBio.CompteTest do
  use BauleBio.DataCase

  alias BauleBio.Compte

  import BauleBio.CompteFixtures
  alias BauleBio.Compte.{Utilisateur, UtilisateurToken}

  describe "get_utilisateur_by_email/1" do
    test "does not return the utilisateur if the email does not exist" do
      refute Compte.get_utilisateur_by_email("unknown@example.com")
    end

    test "returns the utilisateur if the email exists" do
      %{id: id} = utilisateur = utilisateur_fixture()
      assert %Utilisateur{id: ^id} = Compte.get_utilisateur_by_email(utilisateur.email)
    end
  end

  describe "get_utilisateur_by_email_and_password/2" do
    test "does not return the utilisateur if the email does not exist" do
      refute Compte.get_utilisateur_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the utilisateur if the password is not valid" do
      utilisateur = utilisateur_fixture() |> set_password()
      refute Compte.get_utilisateur_by_email_and_password(utilisateur.email, "invalid")
    end

    test "returns the utilisateur if the email and password are valid" do
      %{id: id} = utilisateur = utilisateur_fixture() |> set_password()

      assert %Utilisateur{id: ^id} =
               Compte.get_utilisateur_by_email_and_password(utilisateur.email, valid_utilisateur_password())
    end
  end

  describe "get_utilisateur!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Compte.get_utilisateur!(-1)
      end
    end

    test "returns the utilisateur with the given id" do
      %{id: id} = utilisateur = utilisateur_fixture()
      assert %Utilisateur{id: ^id} = Compte.get_utilisateur!(utilisateur.id)
    end
  end

  describe "register_utilisateur/1" do
    test "requires email to be set" do
      {:error, changeset} = Compte.register_utilisateur(%{})

      assert %{email: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates email when given" do
      {:error, changeset} = Compte.register_utilisateur(%{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum values for email for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Compte.register_utilisateur(%{email: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness" do
      %{email: email} = utilisateur_fixture()
      {:error, changeset} = Compte.register_utilisateur(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Compte.register_utilisateur(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers utilisateurs without password" do
      email = unique_utilisateur_email()
      {:ok, utilisateur} = Compte.register_utilisateur(valid_utilisateur_attributes(email: email))
      assert utilisateur.email == email
      assert is_nil(utilisateur.hashed_password)
      assert is_nil(utilisateur.confirmed_at)
      assert is_nil(utilisateur.password)
    end
  end

  describe "sudo_mode?/2" do
    test "validates the authenticated_at time" do
      now = DateTime.utc_now()

      assert Compte.sudo_mode?(%Utilisateur{authenticated_at: DateTime.utc_now()})
      assert Compte.sudo_mode?(%Utilisateur{authenticated_at: DateTime.add(now, -19, :minute)})
      refute Compte.sudo_mode?(%Utilisateur{authenticated_at: DateTime.add(now, -21, :minute)})

      # minute override
      refute Compte.sudo_mode?(
               %Utilisateur{authenticated_at: DateTime.add(now, -11, :minute)},
               -10
             )

      # not authenticated
      refute Compte.sudo_mode?(%Utilisateur{})
    end
  end

  describe "change_utilisateur_email/3" do
    test "returns a utilisateur changeset" do
      assert %Ecto.Changeset{} = changeset = Compte.change_utilisateur_email(%Utilisateur{})
      assert changeset.required == [:email]
    end
  end

  describe "deliver_utilisateur_update_email_instructions/3" do
    setup do
      %{utilisateur: utilisateur_fixture()}
    end

    test "sends token through notification", %{utilisateur: utilisateur} do
      token =
        extract_utilisateur_token(fn url ->
          Compte.deliver_utilisateur_update_email_instructions(utilisateur, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert utilisateur_token = Repo.get_by(UtilisateurToken, token: :crypto.hash(:sha256, token))
      assert utilisateur_token.utilisateur_id == utilisateur.id
      assert utilisateur_token.sent_to == utilisateur.email
      assert utilisateur_token.context == "change:current@example.com"
    end
  end

  describe "update_utilisateur_email/2" do
    setup do
      utilisateur = unconfirmed_utilisateur_fixture()
      email = unique_utilisateur_email()

      token =
        extract_utilisateur_token(fn url ->
          Compte.deliver_utilisateur_update_email_instructions(%{utilisateur | email: email}, utilisateur.email, url)
        end)

      %{utilisateur: utilisateur, token: token, email: email}
    end

    test "updates the email with a valid token", %{utilisateur: utilisateur, token: token, email: email} do
      assert {:ok, %{email: ^email}} = Compte.update_utilisateur_email(utilisateur, token)
      changed_utilisateur = Repo.get!(Utilisateur, utilisateur.id)
      assert changed_utilisateur.email != utilisateur.email
      assert changed_utilisateur.email == email
      refute Repo.get_by(UtilisateurToken, utilisateur_id: utilisateur.id)
    end

    test "does not update email with invalid token", %{utilisateur: utilisateur} do
      assert Compte.update_utilisateur_email(utilisateur, "oops") ==
               {:error, :transaction_aborted}

      assert Repo.get!(Utilisateur, utilisateur.id).email == utilisateur.email
      assert Repo.get_by(UtilisateurToken, utilisateur_id: utilisateur.id)
    end

    test "does not update email if utilisateur email changed", %{utilisateur: utilisateur, token: token} do
      assert Compte.update_utilisateur_email(%{utilisateur | email: "current@example.com"}, token) ==
               {:error, :transaction_aborted}

      assert Repo.get!(Utilisateur, utilisateur.id).email == utilisateur.email
      assert Repo.get_by(UtilisateurToken, utilisateur_id: utilisateur.id)
    end

    test "does not update email if token expired", %{utilisateur: utilisateur, token: token} do
      {1, nil} = Repo.update_all(UtilisateurToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])

      assert Compte.update_utilisateur_email(utilisateur, token) ==
               {:error, :transaction_aborted}

      assert Repo.get!(Utilisateur, utilisateur.id).email == utilisateur.email
      assert Repo.get_by(UtilisateurToken, utilisateur_id: utilisateur.id)
    end
  end

  describe "change_utilisateur_password/3" do
    test "returns a utilisateur changeset" do
      assert %Ecto.Changeset{} = changeset = Compte.change_utilisateur_password(%Utilisateur{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Compte.change_utilisateur_password(
          %Utilisateur{},
          %{
            "password" => "new valid password"
          },
          hash_password: false
        )

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_utilisateur_password/2" do
    setup do
      %{utilisateur: utilisateur_fixture()}
    end

    test "validates password", %{utilisateur: utilisateur} do
      {:error, changeset} =
        Compte.update_utilisateur_password(utilisateur, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{utilisateur: utilisateur} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Compte.update_utilisateur_password(utilisateur, %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{utilisateur: utilisateur} do
      {:ok, {utilisateur, expired_tokens}} =
        Compte.update_utilisateur_password(utilisateur, %{
          password: "new valid password"
        })

      assert expired_tokens == []
      assert is_nil(utilisateur.password)
      assert Compte.get_utilisateur_by_email_and_password(utilisateur.email, "new valid password")
    end

    test "deletes all tokens for the given utilisateur", %{utilisateur: utilisateur} do
      _ = Compte.generate_utilisateur_session_token(utilisateur)

      {:ok, {_, _}} =
        Compte.update_utilisateur_password(utilisateur, %{
          password: "new valid password"
        })

      refute Repo.get_by(UtilisateurToken, utilisateur_id: utilisateur.id)
    end
  end

  describe "generate_utilisateur_session_token/1" do
    setup do
      %{utilisateur: utilisateur_fixture()}
    end

    test "generates a token", %{utilisateur: utilisateur} do
      token = Compte.generate_utilisateur_session_token(utilisateur)
      assert utilisateur_token = Repo.get_by(UtilisateurToken, token: token)
      assert utilisateur_token.context == "session"
      assert utilisateur_token.authenticated_at != nil

      # Creating the same token for another utilisateur should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%UtilisateurToken{
          token: utilisateur_token.token,
          utilisateur_id: utilisateur_fixture().id,
          context: "session"
        })
      end
    end

    test "duplicates the authenticated_at of given utilisateur in new token", %{utilisateur: utilisateur} do
      utilisateur = %{utilisateur | authenticated_at: DateTime.add(DateTime.utc_now(:second), -3600)}
      token = Compte.generate_utilisateur_session_token(utilisateur)
      assert utilisateur_token = Repo.get_by(UtilisateurToken, token: token)
      assert utilisateur_token.authenticated_at == utilisateur.authenticated_at
      assert DateTime.compare(utilisateur_token.inserted_at, utilisateur.authenticated_at) == :gt
    end
  end

  describe "get_utilisateur_by_session_token/1" do
    setup do
      utilisateur = utilisateur_fixture()
      token = Compte.generate_utilisateur_session_token(utilisateur)
      %{utilisateur: utilisateur, token: token}
    end

    test "returns utilisateur by token", %{utilisateur: utilisateur, token: token} do
      assert {session_utilisateur, token_inserted_at} = Compte.get_utilisateur_by_session_token(token)
      assert session_utilisateur.id == utilisateur.id
      assert session_utilisateur.authenticated_at != nil
      assert token_inserted_at != nil
    end

    test "does not return utilisateur for invalid token" do
      refute Compte.get_utilisateur_by_session_token("oops")
    end

    test "does not return utilisateur for expired token", %{token: token} do
      dt = ~N[2020-01-01 00:00:00]
      {1, nil} = Repo.update_all(UtilisateurToken, set: [inserted_at: dt, authenticated_at: dt])
      refute Compte.get_utilisateur_by_session_token(token)
    end
  end

  describe "get_utilisateur_by_magic_link_token/1" do
    setup do
      utilisateur = utilisateur_fixture()
      {encoded_token, _hashed_token} = generate_utilisateur_magic_link_token(utilisateur)
      %{utilisateur: utilisateur, token: encoded_token}
    end

    test "returns utilisateur by token", %{utilisateur: utilisateur, token: token} do
      assert session_utilisateur = Compte.get_utilisateur_by_magic_link_token(token)
      assert session_utilisateur.id == utilisateur.id
    end

    test "does not return utilisateur for invalid token" do
      refute Compte.get_utilisateur_by_magic_link_token("oops")
    end

    test "does not return utilisateur for expired token", %{token: token} do
      {1, nil} = Repo.update_all(UtilisateurToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Compte.get_utilisateur_by_magic_link_token(token)
    end
  end

  describe "login_utilisateur_by_magic_link/1" do
    test "confirms utilisateur and expires tokens" do
      utilisateur = unconfirmed_utilisateur_fixture()
      refute utilisateur.confirmed_at
      {encoded_token, hashed_token} = generate_utilisateur_magic_link_token(utilisateur)

      assert {:ok, {utilisateur, [%{token: ^hashed_token}]}} =
               Compte.login_utilisateur_by_magic_link(encoded_token)

      assert utilisateur.confirmed_at
    end

    test "returns utilisateur and (deleted) token for confirmed utilisateur" do
      utilisateur = utilisateur_fixture()
      assert utilisateur.confirmed_at
      {encoded_token, _hashed_token} = generate_utilisateur_magic_link_token(utilisateur)
      assert {:ok, {^utilisateur, []}} = Compte.login_utilisateur_by_magic_link(encoded_token)
      # one time use only
      assert {:error, :not_found} = Compte.login_utilisateur_by_magic_link(encoded_token)
    end

    test "raises when unconfirmed utilisateur has password set" do
      utilisateur = unconfirmed_utilisateur_fixture()
      {1, nil} = Repo.update_all(Utilisateur, set: [hashed_password: "hashed"])
      {encoded_token, _hashed_token} = generate_utilisateur_magic_link_token(utilisateur)

      assert_raise RuntimeError, ~r/magic link log in is not allowed/, fn ->
        Compte.login_utilisateur_by_magic_link(encoded_token)
      end
    end
  end

  describe "delete_utilisateur_session_token/1" do
    test "deletes the token" do
      utilisateur = utilisateur_fixture()
      token = Compte.generate_utilisateur_session_token(utilisateur)
      assert Compte.delete_utilisateur_session_token(token) == :ok
      refute Compte.get_utilisateur_by_session_token(token)
    end
  end

  describe "deliver_login_instructions/2" do
    setup do
      %{utilisateur: unconfirmed_utilisateur_fixture()}
    end

    test "sends token through notification", %{utilisateur: utilisateur} do
      token =
        extract_utilisateur_token(fn url ->
          Compte.deliver_login_instructions(utilisateur, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert utilisateur_token = Repo.get_by(UtilisateurToken, token: :crypto.hash(:sha256, token))
      assert utilisateur_token.utilisateur_id == utilisateur.id
      assert utilisateur_token.sent_to == utilisateur.email
      assert utilisateur_token.context == "login"
    end
  end

  describe "inspect/2 for the Utilisateur module" do
    test "does not include password" do
      refute inspect(%Utilisateur{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
