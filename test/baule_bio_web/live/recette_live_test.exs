defmodule BauleBioWeb.RecetteLiveTest do
  use BauleBioWeb.ConnCase

  import Phoenix.LiveViewTest
  import BauleBio.PartageFixtures

  @create_attrs %{description: "some description", ingredient: %{}, nom: "some nom"}
  @update_attrs %{description: "some updated description", ingredient: %{}, nom: "some updated nom"}
  @invalid_attrs %{description: nil, ingredient: nil, nom: nil}
  defp create_recette(_) do
    recette = recette_fixture()

    %{recette: recette}
  end

  describe "Index" do
    setup [:create_recette]

    test "lists all recettes", %{conn: conn, recette: recette} do
      {:ok, _index_live, html} = live(conn, ~p"/recettes")

      assert html =~ "Listing Recettes"
      assert html =~ recette.nom
    end

    test "saves new recette", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/recettes")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Recette")
               |> render_click()
               |> follow_redirect(conn, ~p"/recettes/new")

      assert render(form_live) =~ "New Recette"

      assert form_live
             |> form("#recette-form", recette: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#recette-form", recette: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/recettes")

      html = render(index_live)
      assert html =~ "Recette created successfully"
      assert html =~ "some nom"
    end

    test "updates recette in listing", %{conn: conn, recette: recette} do
      {:ok, index_live, _html} = live(conn, ~p"/recettes")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#recettes-#{recette.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/recettes/#{recette}/edit")

      assert render(form_live) =~ "Edit Recette"

      assert form_live
             |> form("#recette-form", recette: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#recette-form", recette: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/recettes")

      html = render(index_live)
      assert html =~ "Recette updated successfully"
      assert html =~ "some updated nom"
    end

    test "deletes recette in listing", %{conn: conn, recette: recette} do
      {:ok, index_live, _html} = live(conn, ~p"/recettes")

      assert index_live |> element("#recettes-#{recette.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#recettes-#{recette.id}")
    end
  end

  describe "Show" do
    setup [:create_recette]

    test "displays recette", %{conn: conn, recette: recette} do
      {:ok, _show_live, html} = live(conn, ~p"/recettes/#{recette}")

      assert html =~ "Show Recette"
      assert html =~ recette.nom
    end

    test "updates recette and returns to show", %{conn: conn, recette: recette} do
      {:ok, show_live, _html} = live(conn, ~p"/recettes/#{recette}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/recettes/#{recette}/edit?return_to=show")

      assert render(form_live) =~ "Edit Recette"

      assert form_live
             |> form("#recette-form", recette: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#recette-form", recette: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/recettes/#{recette}")

      html = render(show_live)
      assert html =~ "Recette updated successfully"
      assert html =~ "some updated nom"
    end
  end
end
