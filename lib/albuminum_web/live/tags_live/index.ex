defmodule AlbuminumWeb.TagsLive.Index do
  use AlbuminumWeb, :live_view

  alias Albuminum.Gallery

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Tags
        <:actions>
          <.button variant="primary" navigate={~p"/albums"}>
            <.icon name="hero-arrow-left" /> Back to Albums
          </.button>
        </:actions>
      </.header>

      <%= if Enum.empty?(@tags) do %>
        <p class="text-center text-base-content/60 py-8">No tags yet</p>
      <% else %>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mt-6">
          <%= for tag <- @tags do %>
            <div class="card bg-base-200 shadow-sm">
              <div class="card-body">
                <div class="flex justify-between items-start">
                  <.link navigate={~p"/tags/#{tag}"} class="card-title link link-hover">
                    {tag.name}
                  </.link>
                  <button
                    phx-click="delete_tag"
                    phx-value-id={tag.id}
                    data-confirm="Delete this tag? It will be removed from all images."
                    class="btn btn-ghost btn-sm text-error"
                  >
                    <.icon name="hero-trash" class="w-4 h-4" />
                  </button>
                </div>
                <p class="text-sm text-base-content/60">
                  {length(tag.images)} <%= if length(tag.images) == 1, do: "image", else: "images" %>
                </p>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Tags")
     |> assign(:tags, Gallery.list_tags_with_images(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("delete_tag", %{"id" => id}, socket) do
    tag = Gallery.get_tag!(socket.assigns.current_scope, id)
    {:ok, _} = Gallery.delete_tag(tag)

    {:noreply, assign(socket, :tags, Gallery.list_tags_with_images(socket.assigns.current_scope))}
  end
end
