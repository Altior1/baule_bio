defmodule BauleBio.PartageTest do
  use BauleBio.DataCase

  alias BauleBio.Partage

  describe "recettes" do
    alias BauleBio.Partage.Recette

    import BauleBio.PartageFixtures

    @invalid_attrs %{description: nil, nom: nil}

    test "list_recettes/0 returns all recettes" do
      recette = recette_fixture()
      assert Partage.list_recettes() == [recette]
    end

    test "get_recette!/1 returns the recette with given id" do
      recette = recette_fixture()
      assert Partage.get_recette!(recette.id) == recette
    end

    test "create_recette/1 with valid data creates a recette" do
      valid_attrs = %{description: "some description", nom: "some nom"}

      assert {:ok, %Recette{} = recette} = Partage.create_recette(valid_attrs)
      assert recette.description == "some description"
      assert recette.nom == "some nom"
    end

    test "create_recette/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Partage.create_recette(@invalid_attrs)
    end

    test "update_recette/2 with valid data updates the recette" do
      recette = recette_fixture()
      update_attrs = %{description: "some updated description", nom: "some updated nom"}

      assert {:ok, %Recette{} = recette} = Partage.update_recette(recette, update_attrs)
      assert recette.description == "some updated description"
      assert recette.nom == "some updated nom"
    end

    test "update_recette/2 with invalid data returns error changeset" do
      recette = recette_fixture()
      assert {:error, %Ecto.Changeset{}} = Partage.update_recette(recette, @invalid_attrs)
      assert recette == Partage.get_recette!(recette.id)
    end

    test "delete_recette/1 deletes the recette" do
      recette = recette_fixture()
      assert {:ok, %Recette{}} = Partage.delete_recette(recette)
      assert_raise Ecto.NoResultsError, fn -> Partage.get_recette!(recette.id) end
    end

    test "change_recette/1 returns a recette changeset" do
      recette = recette_fixture()
      assert %Ecto.Changeset{} = Partage.change_recette(recette)
    end
  end
end
