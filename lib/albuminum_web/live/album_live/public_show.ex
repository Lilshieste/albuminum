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
                  class="w-full h-32 object-cover rounded-lg"
                />
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
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
     |> assign(:token, token)}
  end

  @impl true
  def handle_info({:album_updated, _album_id}, socket) do
    # Reload album data
    album = Gallery.get_album_with_images_by_share_token!(socket.assigns.token)
    {:noreply, assign(socket, :album, album)}
  end
end
