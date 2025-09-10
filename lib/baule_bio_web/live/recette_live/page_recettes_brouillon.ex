defmodule BauleBioWeb.RecetteLive.PageRecettesBrouillon do
  use BauleBioWeb, :live_view

  alias BauleBio.Partage

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  defp list_recettes do
    Partage.list_recettes()
  end
end
