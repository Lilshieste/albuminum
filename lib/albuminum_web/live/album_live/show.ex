defmodule AlbuminumWeb.AlbumLive.Show do
  use AlbuminumWeb, :live_view

  alias Albuminum.Accounts
  alias Albuminum.Gallery
  alias Albuminum.GooglePhotosPicker
  alias AlbuminumWeb.Live.Components.GooglePhotosBrowser

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
          <div class="space-y-6">
            <%= for {label, key, images} <- @grouped_images do %>
              <div class="border rounded-lg overflow-hidden">
                <button
                  phx-click="toggle_group"
                  phx-value-group={key}
                  class="w-full flex items-center justify-between px-4 py-3 bg-base-200 hover:bg-base-300 transition-colors"
                >
                  <span class="font-medium">
                    {label}
                    <span class="text-base-content/60 ml-2">({length(images)})</span>
                  </span>
                  <.icon
                    name={if MapSet.member?(@collapsed_groups, key), do: "hero-chevron-right", else: "hero-chevron-down"}
                    class="w-5 h-5"
                  />
                </button>

                <%= unless MapSet.member?(@collapsed_groups, key) do %>
                  <div class="p-4 grid grid-cols-2 md:grid-cols-4 gap-4">
                    <%= for image <- images do %>
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
            <% end %>
          </div>
        <% end %>
      </div>

      <.live_component
        module={GooglePhotosBrowser}
        id="google-photos-browser"
        album={@album}
        current_scope={@current_scope}
        current_path={@current_path}
      />
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    scope = socket.assigns.current_scope
    album = Gallery.get_album_with_images!(scope, id)
    available_images = Gallery.list_images_not_in_album(album)
    grouped_images = Gallery.group_images_by_source(available_images)

    {:ok,
     socket
     |> assign(:page_title, album.name)
     |> assign(:album, album)
     |> assign(:available_images, available_images)
     |> assign(:grouped_images, grouped_images)
     |> assign(:collapsed_groups, MapSet.new())}
  end

  @impl true
  def handle_params(_params, uri, socket) do
    # Store current path for OAuth return redirect
    %URI{path: path} = URI.parse(uri)
    {:noreply, assign(socket, :current_path, path)}
  end

  @impl true
  def handle_event("toggle_group", %{"group" => group_key}, socket) do
    collapsed = socket.assigns.collapsed_groups

    updated =
      if MapSet.member?(collapsed, group_key) do
        MapSet.delete(collapsed, group_key)
      else
        MapSet.put(collapsed, group_key)
      end

    {:noreply, assign(socket, :collapsed_groups, updated)}
  end

  def handle_event("add_image", %{"image-id" => image_id}, socket) do
    album = socket.assigns.album
    image = Gallery.get_image!(image_id)

    case Gallery.add_image_to_album(album, image) do
      {:ok, _} ->
        {:noreply,
         socket
         |> refresh_album_data()
         |> put_flash(:info, "Image added")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to add image")}
    end
  end

  def handle_event("remove_image", %{"image-id" => image_id}, socket) do
    album = socket.assigns.album
    image = Gallery.get_image!(image_id)

    Gallery.remove_image_from_album(album, image)

    {:noreply,
     socket
     |> refresh_album_data()
     |> put_flash(:info, "Image removed")}
  end

  def handle_event("reorder", %{"ids" => image_ids}, socket) do
    scope = socket.assigns.current_scope
    album = socket.assigns.album

    Gallery.reorder_album_images(album, image_ids)
    album = Gallery.get_album_with_images!(scope, album.id)

    {:noreply, assign(socket, :album, album)}
  end

  # ============================================================================
  # Google Photos Picker Integration
  # ============================================================================

  @impl true
  def handle_info({:check_google_connection, component_id}, socket) do
    user = socket.assigns.current_scope.user

    case Accounts.get_google_access_token(user) do
      {:ok, _token} ->
        send_update(GooglePhotosBrowser, id: component_id, status: :idle)

      {:error, _} ->
        # Token missing, refresh failed, or no photos scope - need re-auth
        send_update(GooglePhotosBrowser, id: component_id, status: :not_connected)
    end

    {:noreply, socket}
  end

  def handle_info({:start_photo_picker, component_id, album_id}, socket) do
    user = socket.assigns.current_scope.user

    case Accounts.get_google_access_token(user) do
      {:ok, token} ->
        case GooglePhotosPicker.create_session(token) do
          {:ok, %{"id" => session_id, "pickerUri" => picker_uri}} ->
            # Open picker popup via JS hook
            send_update(GooglePhotosBrowser,
              id: component_id,
              status: :polling,
              session_id: session_id
            )

            # Push event to open popup (append /autoclose for auto-close behavior)
            {:noreply,
             socket
             |> assign(:picker_session_id, session_id)
             |> assign(:picker_component_id, component_id)
             |> assign(:picker_album_id, album_id)
             |> push_event("open_picker", %{url: "#{picker_uri}/autoclose"})
             |> schedule_poll()}

          {:error, reason} ->
            require Logger
            Logger.error("Failed to create picker session: #{inspect(reason)}")

            send_update(GooglePhotosBrowser,
              id: component_id,
              status: :error,
              error_message: "Failed to start photo picker"
            )

            {:noreply, socket}
        end

      {:error, _} ->
        # Token missing, refresh failed, or no photos scope - need re-auth
        send_update(GooglePhotosBrowser, id: component_id, status: :not_connected)
        {:noreply, socket}
    end
  end

  def handle_info(:poll_picker_session, socket) do
    session_id = socket.assigns[:picker_session_id]
    component_id = socket.assigns[:picker_component_id]
    user = socket.assigns.current_scope.user

    if is_nil(session_id) do
      {:noreply, socket}
    else
      case Accounts.get_google_access_token(user) do
        {:ok, token} ->
          case GooglePhotosPicker.get_session_status(session_id, token) do
            {:ready, _body} ->
              # User finished selecting - fetch the items
              send(self(), :fetch_picked_items)
              {:noreply, socket}

            {:pending, _body} ->
              # Still picking, poll again
              {:noreply, schedule_poll(socket)}

            {:error, reason} ->
              require Logger
              Logger.error("Picker session poll error: #{inspect(reason)}")

              send_update(GooglePhotosBrowser,
                id: component_id,
                status: :error,
                error_message: "Picker session expired or failed"
              )

              {:noreply, clear_picker_state(socket)}
          end

        {:error, _} ->
          # Token expired and refresh failed - need re-auth
          send_update(GooglePhotosBrowser, id: component_id, status: :not_connected)
          {:noreply, clear_picker_state(socket)}
      end
    end
  end

  def handle_info(:fetch_picked_items, socket) do
    session_id = socket.assigns[:picker_session_id]
    component_id = socket.assigns[:picker_component_id]
    album_id = socket.assigns[:picker_album_id]
    user = socket.assigns.current_scope.user

    case Accounts.get_google_access_token(user) do
      {:ok, token} ->
        case GooglePhotosPicker.list_picked_items(session_id, token) do
          {:ok, %{"mediaItems" => items}} when is_list(items) and length(items) > 0 ->
            send_update(GooglePhotosBrowser,
              id: component_id,
              status: :importing,
              import_count: length(items)
            )

            # Import all selected photos
            send(self(), {:import_picked_photos, album_id, items})
            {:noreply, socket}

          {:ok, _} ->
            # No items selected
            send_update(GooglePhotosBrowser, id: component_id, status: :idle)
            {:noreply, clear_picker_state(socket) |> put_flash(:info, "No photos selected")}

          {:error, reason} ->
            require Logger
            Logger.error("Failed to fetch picked items: #{inspect(reason)}")

            send_update(GooglePhotosBrowser,
              id: component_id,
              status: :error,
              error_message: "Failed to fetch selected photos"
            )

            {:noreply, clear_picker_state(socket)}
        end

      {:error, _} ->
        # Token expired and refresh failed - need re-auth
        send_update(GooglePhotosBrowser, id: component_id, status: :not_connected)
        {:noreply, clear_picker_state(socket)}
    end
  end

  def handle_info({:import_picked_photos, album_id, items}, socket) do
    require Logger
    scope = socket.assigns.current_scope
    component_id = socket.assigns[:picker_component_id]
    album = Gallery.get_album!(scope, album_id)
    user = scope.user

    # Log what we received from Photo Picker API
    Logger.info("Received #{length(items)} items from Photo Picker")
    Logger.debug("First item structure: #{inspect(List.first(items))}")

    # Get access token for downloading images
    {:ok, access_token} = Accounts.get_google_access_token(user)

    # Import all photos and log failures
    results = Enum.map(items, fn item ->
      result = Gallery.import_google_photo_to_album(album, item, access_token)

      case result do
        {:ok, _} ->
          result

        {:error, reason} ->
          Logger.error("Failed to import photo #{item["id"]}: #{inspect(reason)}")
          Logger.debug("Media item details: #{inspect(item)}")
          result
      end
    end)

    success_count = Enum.count(results, &match?({:ok, _}, &1))
    failure_count = length(results) - success_count

    send_update(GooglePhotosBrowser, id: component_id, status: :idle)

    flash_msg =
      if failure_count > 0 do
        "Imported #{success_count} photo(s), #{failure_count} failed (check logs)"
      else
        "Imported #{success_count} photo(s)!"
      end

    {:noreply,
     socket
     |> refresh_album_data()
     |> clear_picker_state()
     |> put_flash(:info, flash_msg)}
  end

  def handle_info({:cancel_picker_session, session_id}, socket) do
    user = socket.assigns.current_scope.user

    # Best effort cleanup
    case Accounts.get_google_access_token(user) do
      {:ok, token} -> GooglePhotosPicker.delete_session(session_id, token)
      _ -> :ok
    end

    {:noreply, clear_picker_state(socket)}
  end

  defp schedule_poll(socket) do
    Process.send_after(self(), :poll_picker_session, 3000)
    socket
  end

  defp clear_picker_state(socket) do
    socket
    |> assign(:picker_session_id, nil)
    |> assign(:picker_component_id, nil)
    |> assign(:picker_album_id, nil)
  end

  defp refresh_album_data(socket) do
    scope = socket.assigns.current_scope
    album = socket.assigns.album

    album = Gallery.get_album_with_images!(scope, album.id)
    available_images = Gallery.list_images_not_in_album(album)
    grouped_images = Gallery.group_images_by_source(available_images)

    socket
    |> assign(:album, album)
    |> assign(:available_images, available_images)
    |> assign(:grouped_images, grouped_images)
  end
end
