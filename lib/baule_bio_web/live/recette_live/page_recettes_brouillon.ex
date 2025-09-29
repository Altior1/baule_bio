defmodule BauleBioWeb.RecetteLive.PageRecettesBrouillon do
  use BauleBioWeb, :live_view

  alias BauleBio.Partage
  alias BauleBio.Compte.Scope

  @impl true
  def mount(_params, _session, socket) do
    recettes = list_recettes(socket.assigns.current_scope)
    {:ok, assign(socket, recettes: recettes)}
  end

  defp list_recettes(%Scope{} = _current_scope) do
    Partage.list_recettes()
  end
end
