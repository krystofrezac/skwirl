defmodule SkwirlWeb.ProvidersLive do
  use SkwirlWeb, :live_view

  alias Skwirl.Providers

  def mount(_params, _session, socket) do
    providers = Providers.list_providers()

    {:ok,
     socket
     |> assign(:providers, providers)
     |> assign(:selected_provider, nil)}
  end

  def handle_event("show_code", %{"id" => id}, socket) do
    provider = Enum.find(socket.assigns.providers, &(&1.id == id))
    {:noreply, assign(socket, :selected_provider, provider)}
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, :selected_provider, nil)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="min-h-screen">
        <div class="mb-8">
          <h1 class="text-4xl font-bold text-base-content">Providers</h1>
          <p class="mt-2 text-base-content/70">Manage your installed providers</p>
        </div>

        <%= if @providers == [] do %>
          <div class="flex flex-col items-center justify-center py-24">
            <div class="rounded-full bg-base-200 p-6 mb-4">
              <.icon name="hero-puzzle-piece" class="w-12 h-12 text-base-content/40" />
            </div>
            <p class="text-lg text-base-content/60">No providers installed yet</p>
            <p class="text-sm text-base-content/40 mt-1">
              Install a provider to get started
            </p>
          </div>
        <% else %>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <div
              :for={provider <- @providers}
              phx-click="show_code"
              phx-value-id={provider.id}
              class="card bg-base-100 border border-base-300 hover:border-primary hover:shadow-lg transition-all duration-200 cursor-pointer group h-32"
            >
              <div class="card-body flex items-center justify-center p-6">
                <h2 class="card-title text-xl text-center group-hover:text-primary transition-colors">
                  {provider.name}
                </h2>
              </div>
            </div>
          </div>
        <% end %>

        <%= if @selected_provider do %>
          <div
            class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm transition-opacity duration-300"
            phx-click="close_modal"
            phx-window-keydown="close_modal"
            phx-key="escape"
          >
            <div
              class="relative bg-base-100 rounded-lg shadow-2xl max-w-4xl w-full mx-4 max-h-[90vh] flex flex-col transition-all duration-300"
              phx-click={JS.exec("phx-remove", to: "nothing")}
            >
              <div class="flex items-center justify-between p-6 border-b border-base-300">
                <h2 class="text-2xl font-bold text-base-content">
                  {@selected_provider.name}
                </h2>
                <button
                  type="button"
                  phx-click="close_modal"
                  class="btn btn-ghost btn-sm btn-circle"
                  aria-label="Close modal"
                >
                  <.icon name="hero-x-mark" class="w-5 h-5" />
                </button>
              </div>

              <div class="flex-1 overflow-auto p-6">
                <pre class="bg-base-200 rounded-lg p-4 overflow-x-auto"><code
                    class="font-mono text-sm text-base-content"
                    phx-no-format
                  >{@selected_provider.lua_code}</code></pre>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end
end
