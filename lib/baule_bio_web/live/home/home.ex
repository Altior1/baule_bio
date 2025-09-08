defmodule BauleBioWeb.HomeLive do
  use BauleBioWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1>Bienvenue sur le site BauleBio</h1>
      <p>
        Vous y trouverez des recettes, des légumes de saison et des nouvelles des champs. C'est un plaisir de vous recevoir
      </p>
      <p>
        Découvrez nos produits locaux et de saison, ainsi que des conseils pour une alimentation saine et équilibrée.
      </p>
      <img src="/images/baule_bio_logo.png" alt="Logo Baule Bio" class="w-32 h-32 mt-4" />
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
