defmodule BauleBioWeb.Ingredients.Form do
  @moduledoc """
  La vue pour créer ou éditer un ingrédient
  """

  use BauleBioWeb, :live_view
  alias BauleBio.Partage
  alias BauleBio.Partage.Ingredient

  @impl true
  def mount(_params, _session, socket) do
    changeset = Partage.change_ingredient()
    {:ok, assign(socket, changeset: changeset)}
  end
end
