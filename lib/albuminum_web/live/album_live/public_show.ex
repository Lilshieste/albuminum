defmodule AlbuminumWeb.AlbumLive.PublicShow do
  @moduledoc """
  Public read-only view of a shared album.
  No authentication required - accessed via share token.
  """

  use AlbuminumWeb, :live_view

  alias Albuminum.Gallery

  @impl true
  def render(%{not_found: true} = assigns) do
    ~H"""
    <Layouts.public flash={@flash}>
      <div class="flex flex-col items-center justify-center py-20 text-center">
        <.icon name="hero-photo" class="w-16 h-16 text-base-content/30 mb-4" />
        <h1 class="text-2xl font-semibold mb-2">Album Not Found</h1>
        <p class="text-base-content/60 mb-6">
          This album may have been removed or is no longer shared.
        </p>
        <a href="/" class="btn btn-primary">Go Home</a>
      </div>
    </Layouts.public>
    """
  end

  def render(assigns) do
    ~H"""
    <Layouts.public flash={@flash}>
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
                  alt={album_image.image.alt_text || album_image.image.filename}
                  class="w-full h-32 object-cover rounded-lg cursor-pointer"
                  phx-click="open_lightbox"
                  phx-value-image-id={album_image.image.id}
                />
                <%= if album_image.image.caption do %>
                  <p class="mt-1 text-sm text-base-content/70 line-clamp-2">
                    {album_image.image.caption}
                  </p>
                <% end %>
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
          <div class="flex flex-col items-center">
            <img
              src={@selected_image.path}
              alt={@selected_image.alt_text || @selected_image.filename}
              class="max-h-[80vh] max-w-[90vw] object-contain"
              phx-click="close_lightbox"
            />
            <%= if @selected_image.caption do %>
              <p class="mt-4 text-white text-center max-w-2xl px-4">
                {@selected_image.caption}
              </p>
            <% end %>
          </div>
        </div>
      <% end %>
    </Layouts.public>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    case fetch_album(token) do
      {:ok, album} ->
        if connected?(socket) do
          Gallery.subscribe_to_album(album.id)
        end

        {:ok,
         socket
         |> assign(:page_title, album.name)
         |> assign(:album, album)
         |> assign(:token, token)
         |> assign(:selected_image, nil)
         |> assign(:not_found, false)
         |> assign(:hide_user_menu, true)}

      :not_found ->
        {:ok,
         socket
         |> assign(:page_title, "Not Found")
         |> assign(:not_found, true)
         |> assign(:hide_user_menu, true)}
    end
  end

  defp fetch_album(token) do
    {:ok, Gallery.get_album_with_images_by_share_token!(token)}
  rescue
    Ecto.NoResultsError -> :not_found
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
    # Reload album data (may have been unshared)
    case fetch_album(socket.assigns.token) do
      {:ok, album} ->
        {:noreply, assign(socket, :album, album)}

      :not_found ->
        {:noreply, assign(socket, :not_found, true)}
    end
  end
end
