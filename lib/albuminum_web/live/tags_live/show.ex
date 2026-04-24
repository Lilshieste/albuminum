defmodule AlbuminumWeb.TagsLive.Show do
  use AlbuminumWeb, :live_view

  alias Albuminum.Gallery

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@ tag.name}
        <:actions>
          <.button variant="primary" navigate={~p"/tags"}>
            <.icon name="hero-arrow-left" /> Back
          </.button>
        </:actions>
      </.header>

      <%= if Enum.empty?(@tag.images) do %>
        <p class="text-center text-base-content/60 py-8">No images with this tag</p>
      <% else %>
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mt-6">
          <%= for image <- @tag.images do %>
            <div class="relative group">
              <img
                src={image.path}
                alt={image.filename}
                class="w-full h-32 object-cover rounded-lg"
              />
              <span class="absolute bottom-2 left-2 bg-black/50 text-white text-xs px-2 py-1 rounded">
                {image.filename}
              </span>
            </div>
          <% end %>
        </div>
      <% end %>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    tag = Gallery.get_tag_with_images!(socket.assigns.current_scope, id)

    {:ok,
     socket
     |> assign(:page_title, tag.name)
     |> assign(:tag, tag)}
  end
end
