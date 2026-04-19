defmodule AlbuminumWeb.AlbumLive.PublicShow do
  @moduledoc """
  Public read-only view of a shared album.
  No authentication required - accessed via share token.
  """

  use AlbuminumWeb, :live_view

  alias Albuminum.Gallery

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@album.name}
        <:subtitle>{@album.description}</:subtitle>
      </.header>

      <div class="mt-8">
        <%= if Enum.empty?(@album.album_images) do %>
          <p class="text-gray-500 italic">This album is empty.</p>
        <% else %>
          <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
            <%= for album_image <- @album.album_images do %>
              <div class="relative">
                <img
                  src={album_image.image.path}
                  alt={album_image.image.filename}
                  class="w-full h-32 object-cover rounded-lg cursor-pointer"
                  phx-click="open_lightbox"
                  phx-value-image-id={album_image.image.id}
                />
              </div>
            <% end %>
          </div>
        <% end %>
      </div>

      <%= if @selected_image do %>
        <div
          id="lightbox"
          class="fixed inset-0 z-50 flex items-center justify-center bg-black/80"
          phx-click="close_lightbox"
          phx-window-keydown="close_lightbox"
          phx-key="Escape"
        >
          <button
            class="absolute top-4 right-4 text-white hover:text-gray-300"
            phx-click="close_lightbox"
          >
            <.icon name="hero-x-mark" class="w-8 h-8" />
          </button>
          <img
            src={@selected_image.path}
            alt={@selected_image.filename}
            class="max-h-[90vh] max-w-[90vw] object-contain"
            phx-click="close_lightbox"
          />
        </div>
      <% end %>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    album = Gallery.get_album_with_images_by_share_token!(token)

    # Subscribe to realtime updates
    if connected?(socket) do
      Gallery.subscribe_to_album(album.id)
    end

    {:ok,
     socket
     |> assign(:page_title, album.name)
     |> assign(:album, album)
     |> assign(:token, token)
     |> assign(:selected_image, nil)}
  end

  @impl true
  def handle_event("open_lightbox", %{"image-id" => image_id}, socket) do
    image = Gallery.get_image!(image_id)
    {:noreply, assign(socket, :selected_image, image)}
  end

  def handle_event("close_lightbox", _, socket) do
    {:noreply, assign(socket, :selected_image, nil)}
  end

  @impl true
  def handle_info({:album_updated, _album_id}, socket) do
    # Reload album data
    album = Gallery.get_album_with_images_by_share_token!(socket.assigns.token)
    {:noreply, assign(socket, :album, album)}
  end
end
