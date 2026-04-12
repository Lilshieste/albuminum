defmodule AlbuminumWeb.AlbumLive.Show do
  use AlbuminumWeb, :live_view

  alias Albuminum.Gallery

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@album.name}
        <:subtitle>{@album.description}</:subtitle>
        <:actions>
          <.button navigate={~p"/albums"}>
            <.icon name="hero-arrow-left" /> Back
          </.button>
          <.button variant="primary" navigate={~p"/albums/#{@album}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit
          </.button>
        </:actions>
      </.header>

      <div class="mt-8">
        <h2 class="text-lg font-semibold mb-4">Images in Album</h2>

        <%= if Enum.empty?(@album.album_images) do %>
          <p class="text-gray-500 italic">No images yet. Add some below!</p>
        <% else %>
          <p class="text-sm text-base-content/60 mb-2">Drag to reorder</p>
          <div id="sortable-images" phx-hook="Sortable" class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
            <%= for album_image <- @album.album_images do %>
              <div class="relative group" data-sortable-id={album_image.image.id}>
                <img
                  src={album_image.image.path}
                  alt={album_image.image.filename}
                  class="w-full h-32 object-cover rounded-lg pointer-events-none"
                />
                <button
                  phx-click="remove_image"
                  phx-value-image-id={album_image.image.id}
                  class="absolute top-2 right-2 bg-red-500 text-white rounded-full p-1 opacity-0 group-hover:opacity-100 transition-opacity"
                >
                  <.icon name="hero-x-mark" class="w-4 h-4" />
                </button>
                <span class="absolute bottom-2 left-2 bg-black/50 text-white text-xs px-2 py-1 rounded">
                  #{album_image.position + 1}
                </span>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>

      <div class="mt-8 border-t pt-8">
        <h2 class="text-lg font-semibold mb-4">Available Images</h2>

        <%= if Enum.empty?(@available_images) do %>
          <p class="text-gray-500 italic">All images have been added to this album.</p>
        <% else %>
          <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
            <%= for image <- @available_images do %>
              <div
                class="cursor-pointer hover:ring-2 hover:ring-blue-500 rounded-lg overflow-hidden"
                phx-click="add_image"
                phx-value-image-id={image.id}
              >
                <img
                  src={image.path}
                  alt={image.filename}
                  class="w-full h-32 object-cover"
                />
                <p class="text-sm text-center py-1 bg-gray-100">{image.filename}</p>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    scope = socket.assigns.current_scope
    album = Gallery.get_album_with_images!(scope, id)
    available_images = Gallery.list_images_not_in_album(album)

    {:ok,
     socket
     |> assign(:page_title, album.name)
     |> assign(:album, album)
     |> assign(:available_images, available_images)}
  end

  @impl true
  def handle_event("add_image", %{"image-id" => image_id}, socket) do
    scope = socket.assigns.current_scope
    album = socket.assigns.album
    image = Gallery.get_image!(image_id)

    case Gallery.add_image_to_album(album, image) do
      {:ok, _} ->
        album = Gallery.get_album_with_images!(scope, album.id)
        available_images = Gallery.list_images_not_in_album(album)

        {:noreply,
         socket
         |> assign(:album, album)
         |> assign(:available_images, available_images)
         |> put_flash(:info, "Image added")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to add image")}
    end
  end

  def handle_event("remove_image", %{"image-id" => image_id}, socket) do
    scope = socket.assigns.current_scope
    album = socket.assigns.album
    image = Gallery.get_image!(image_id)

    Gallery.remove_image_from_album(album, image)

    album = Gallery.get_album_with_images!(scope, album.id)
    available_images = Gallery.list_images_not_in_album(album)

    {:noreply,
     socket
     |> assign(:album, album)
     |> assign(:available_images, available_images)
     |> put_flash(:info, "Image removed")}
  end

  def handle_event("reorder", %{"ids" => image_ids}, socket) do
    scope = socket.assigns.current_scope
    album = socket.assigns.album

    Gallery.reorder_album_images(album, image_ids)
    album = Gallery.get_album_with_images!(scope, album.id)

    {:noreply, assign(socket, :album, album)}
  end
end
