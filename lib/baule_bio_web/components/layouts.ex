defmodule BauleBioWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use BauleBioWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header class="navbar px-4 sm:px-6 lg:px-8">
      <div class="flex-1">
        <a href={~p"/"} class="btn btn-ghost btn-sm rounded-btn">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 32 32"
            width="28"
            height="28"
            class="inline-block mr-2 align-middle"
          >
            <g>
              <!-- Outer layer -->
              <ellipse
                cx="16"
                cy="16"
                rx="12"
                ry="14"
                fill="#e2c290"
                stroke="#bfa76f"
                stroke-width="2"
              />
              <!-- Middle layer -->
              <ellipse
                cx="16"
                cy="16"
                rx="8"
                ry="10"
                fill="#f5e6b2"
                stroke="#d1c08a"
                stroke-width="1.5"
              />
              <!-- Inner layer -->
              <ellipse cx="16" cy="16" rx="4" ry="6" fill="#fffbe6" stroke="#e2c290" stroke-width="1" />
              <!-- Tor onion: layered inner ellipses -->
              <ellipse
                cx="16"
                cy="16"
                rx="2.5"
                ry="4"
                fill="#e2c290"
                stroke="#bfa76f"
                stroke-width="0.7"
              />
              <ellipse
                cx="16"
                cy="16"
                rx="1.2"
                ry="2.2"
                fill="#fffbe6"
                stroke="#d1c08a"
                stroke-width="0.5"
              />
              <!-- Onion root -->
              <rect x="14" y="28" width="4" height="3" rx="1" fill="#bfa76f" />
              <!-- Onion sprout (Tor-style, more curved) -->
              <path d="M16 6 Q15 2, 18 4 Q17 7, 16 6" stroke="#7bb661" stroke-width="1.5" fill="none" />
            </g>
          </svg>
          <h1>Baule Bio</h1>
        </a>
      </div>
      <div class="flex-none">
        <ul class="flex flex-column px-1 space-x-4 items-center">
          <li>
            <a href={~p"/recettes"} class="btn btn-ghost">Lien vers les recettes</a>
          </li>
          <li>
            <a href={~p"/recettes/new"} class="btn btn-ghost">proposer une recettes</a>
          </li>
          <li>
            <a href={~p"/ingredients"} class="btn btn-ghost">Lien vers les ingrédients</a>
          </li>
          <li>
            <a href={~p"/ingredients/new"} class="btn btn-ghost">ajouter un ingrédient</a>
          </li>
          <li>
            <.theme_toggle />
          </li>
        </ul>
      </div>
    </header>

    <main class="max-width: 50vw; max-height: 50vh;">
      <div
        class="mx-auto space-y-4"
        style="max-width: 40vw; max-height: 10vh;"
      >
        {render_slot(@inner_block)}
      </div>
    </main>

    <.footer />

    <.flash_group flash={@flash} />
    """
  end

  defp footer(assigns) do
    ~H"""
    <footer
      class="footer footer-center p-4 bg-base-200 text-base-content rounded"
      style="position: fixed; left: 0; bottom: 0; width: 100%;"
    >
      <div>
        <p>© 2024 - Baule Bio</p>
      </div>
    </footer>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
