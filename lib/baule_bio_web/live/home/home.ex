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
      <div class="image-container mt-4 flex justify-center items-center overflow-hidden rounded-lg shadow-lg w-full h-64">
        <img
          src={~p"/images/champ.jpg"}
          alt="Image de champ"
        />
      </div>

      <.carrousel />
    </Layouts.app>
    """
  end

  defp carrousel(assigns) do
    ~H"""
    <div class="mt-8">
      <h2 class="text-2xl font-bold mb-4">Nos produits phares</h2>
      <div class="carousel-container relative overflow-hidden">
        <div class="carousel flex space-x-4 transition-transform duration-500 ease-in-out">
          <div class="carousel-item min-w-full">
            <img
              src={~p"/images/tomate.jpg"}
              alt="Produit 1"
              class="w-full h-64 object-cover rounded-lg shadow-md"
            />
            <div class="mt-2 text-center">Tomates bio</div>
          </div>
          <div class="carousel-item min-w-full">
            <img
              src={~p"/images/courgette.jpg"}
              alt="Produit 2"
              class="w-full h-64 object-cover rounded-lg shadow-md"
            />
            <div class="mt-2 text-center">Courgettes fraîches</div>
          </div>
          <div class="carousel-item min-w-full">
            <img
              src={~p"/images/salade.webp"}
              alt="Produit 3"
              class="w-full h-64 object-cover rounded-lg shadow-md"
            />
            <div class="mt-2 text-center">Salades croquantes</div>
          </div>
        </div>
        <!-- Navigation buttons can be added here -->
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
