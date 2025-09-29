defmodule BauleBioWeb.RecetteLive.AdminTest do
  use BauleBioWeb.ConnCase
  import Phoenix.LiveViewTest
  alias BauleBio.{Repo, Partage}
  alias BauleBio.Compte.Utilisateur
  alias BauleBio.Partage.Recette

  setup do
    # Créer un admin et un utilisateur normal
    admin =
      Repo.insert!(%Utilisateur{
        email: "admin@test.fr",
        hashed_password: Bcrypt.hash_pwd_salt("motdepasse123"),
        role: "admin",
        confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })

    user =
      Repo.insert!(%Utilisateur{
        email: "user@test.fr",
        hashed_password: Bcrypt.hash_pwd_salt("motdepasse123"),
        role: "utilisateur",
        confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })

    # Créer une recette en attente de validation
    recette =
      Repo.insert!(%Recette{
        nom: "Tarte aux pommes bio",
        description: "Une délicieuse tarte",
        status: :submitted,
        auteur_id: user.id
      })

    {:ok, admin: admin, user: user, recette: recette}
  end

  test "seul l'admin peut accéder à la page d'administration", %{
    conn: conn,
    admin: admin,
    user: user
  } do
    # Test avec admin
    conn = log_in_utilisateur(conn, admin)
    {:ok, _view, html} = live(conn, "/admin/recettes")
    assert html =~ "Administration - Validation des recettes"

    # Test avec utilisateur normal - il devrait être redirigé
    conn = log_in_utilisateur(conn, user)

    assert {:error, {:live_redirect, %{to: "/", flash: %{"error" => "Accès non autorisé"}}}} =
             live(conn, "/admin/recettes")
  end

  test "l'admin peut publier une recette", %{conn: conn, admin: admin, recette: recette} do
    conn = log_in_utilisateur(conn, admin)
    {:ok, view, _html} = live(conn, "/admin/recettes")

    # Publier la recette
    view |> element("button[phx-click=publish][phx-value-id='#{recette.id}']") |> render_click()

    # Vérifier que le statut a changé
    updated_recette = Repo.get!(Recette, recette.id)
    assert updated_recette.status == :published
  end

  test "les recettes publiées apparaissent dans la liste publique", %{
    conn: conn,
    recette: recette
  } do
    # Mettre la recette en statut publié
    Partage.update_recette(recette, %{status: :published})

    # Vérifier qu'elle apparaît dans la liste publique
    {:ok, _view, html} = live(conn, "/recettes")
    assert html =~ "Tarte aux pommes bio"
  end

  test "les recettes non publiées n'apparaissent pas dans la liste publique", %{
    conn: conn,
    recette: _recette
  } do
    # La recette est en statut :submitted par défaut
    {:ok, _view, html} = live(conn, "/recettes")
    refute html =~ "Tarte aux pommes bio"
  end
end
