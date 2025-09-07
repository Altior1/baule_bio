defmodule BauleBioWeb.HomeLive do
  use BauleBioWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app>
      <h1>Bienvenue sur le site BauleBio</h1>
      <p>
        Vous y trouverez des recettes, des légumes de saison et des nouvelles des champs. C'est un plaisir de vous recevoir
      </p>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
