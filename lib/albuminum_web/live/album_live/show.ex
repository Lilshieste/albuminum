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
          <%= if @album_share do %>
            <.button phx-click="toggle_share" variant="primary">
              <.icon name="hero-link" /> Sharing
            </.button>
          <% else %>
            <.button phx-click="toggle_share">
              <.icon name="hero-share" /> Share
            </.button>
          <% end %>
        </:actions>
      </.header>

      <%= if @album_share do %>
        <div class="mt-4 p-4 bg-base-200 rounded-lg">
          <div class="flex items-center gap-4">
            <span class="text-sm font-medium">Share link:</span>
            <code class="flex-1 text-sm bg-base-300 px-3 py-2 rounded" id="share-url">
              {url(~p"/view/#{@album_share.token}")}
            </code>
            <button
              phx-click={JS.dispatch("phx:copy", to: "#share-url")}
              class="btn btn-sm btn-ghost"
              title="Copy link"
            >
              <.icon name="hero-clipboard" class="w-4 h-4" />
            </button>
            <button phx-click="toggle_share" class="btn btn-sm btn-error btn-ghost">
              Stop Sharing
            </button>
          </div>
        </div>
      <% end %>

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
                  alt={album_image.image.alt_text || album_image.image.filename}
                  class="w-full h-32 object-cover rounded-lg cursor-pointer"
                  phx-click="open_lightbox"
                  phx-value-image-id={album_image.image.id}
                />
                <button
                  phx-click="remove_image"
                  phx-value-image-id={album_image.image.id}
                  class="absolute top-2 right-2 bg-red-500 text-white rounded-full p-1 opacity-0 group-hover:opacity-100 transition-opacity"
                >
                  <.icon name="hero-x-mark" class="w-4 h-4" />
                </button>
                <button
                  phx-click="open_details"
                  phx-value-image-id={album_image.image.id}
                  class="absolute bottom-2 right-2 bg-black/50 text-white rounded-full p-1 opacity-0 group-hover:opacity-100 transition-opacity hover:bg-black/70"
                >
                  <.icon name="hero-information-circle" class="w-4 h-4" />
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
        <div class="flex items-center justify-between mb-4">
          <h2 class="text-lg font-semibold">Available Images</h2>

          <%= if not Enum.empty?(@all_tags) do %>
            <div class="flex items-center gap-2">
              <span class="text-sm text-base-content/60">Filter by tags:</span>
              <div class="flex flex-wrap gap-1">
                <%= for tag <- @all_tags do %>
                  <button
                    phx-click="toggle_tag_filter"
                    phx-value-tag-id={tag.id}
                    class={"badge cursor-pointer #{if MapSet.member?(@selected_tag_ids, tag.id), do: "badge-primary", else: "badge-ghost"}"}
                  >
                    {tag.name}
                  </button>
                <% end %>
                <%= if MapSet.size(@selected_tag_ids) > 0 do %>
                  <button phx-click="clear_tag_filter" class="text-xs text-error hover:underline ml-2">
                    Clear
                  </button>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>

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
                      <div class="relative group rounded-lg overflow-hidden">
                        <div
                          class="cursor-pointer hover:ring-2 hover:ring-blue-500"
                          phx-click="add_image"
                          phx-value-image-id={image.id}
                        >
                          <img
                            src={image.path}
                            alt={image.alt_text || image.filename}
                            class="w-full h-32 object-cover"
                          />
                          <p class="text-sm text-center py-1 bg-gray-100">{image.filename}</p>
                        </div>
                        <button
                          phx-click="open_details"
                          phx-value-image-id={image.id}
                          class="absolute bottom-8 right-2 bg-black/50 text-white rounded-full p-1 opacity-0 group-hover:opacity-100 transition-opacity hover:bg-black/70"
                        >
                          <.icon name="hero-information-circle" class="w-4 h-4" />
                        </button>
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

      <%= if @details_image do %>
        <div
          id="image-details-modal"
          class="fixed inset-0 z-50 flex items-center justify-center bg-black/80"
          phx-window-keydown="close_details"
          phx-key="Escape"
        >
          <div
            class="bg-base-100 rounded-lg max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto"
            phx-click-away="close_details"
          >
            <div class="p-6">
              <div class="flex justify-between items-start mb-4">
                <h2 class="text-lg font-semibold">Image Details</h2>
                <button phx-click="close_details" class="btn btn-ghost btn-sm">
                  <.icon name="hero-x-mark" class="w-5 h-5" />
                </button>
              </div>

              <img
                src={@details_image.path}
                alt={@details_image.alt_text || @details_image.filename}
                class="w-full h-48 object-contain mb-4 rounded bg-base-200"
              />

              <.form
                for={@details_form}
                id="image-details-form"
                phx-change="validate_details"
                phx-submit="save_details"
              >
                <.input field={@details_form[:alt_text]} type="textarea" label="Alt Text"
                        placeholder="Describe the image for accessibility..." rows="2" />
                <.input field={@details_form[:caption]} type="textarea" label="Caption"
                        placeholder="Add a caption..." rows="3" />

                <footer class="mt-6 flex gap-2">
                  <.button type="submit" variant="primary" phx-disable-with="Saving...">
                    Save Changes
                  </.button>
                  <.button type="button" phx-click="close_details">
                    Cancel
                  </.button>
                </footer>
              </.form>

              <div class="mt-6 pt-6 border-t border-base-300">
                <label class="label mb-1">
                  <span class="label-text font-medium">Tags</span>
                </label>
                <div class="flex flex-wrap gap-2 mb-2 min-h-[2rem]">
                  <%= for tag <- @image_tags do %>
                    <span class="badge badge-primary gap-1">
                      {tag.name}
                      <button
                        type="button"
                        phx-click="remove_tag"
                        phx-value-tag-id={tag.id}
                        class="hover:text-error"
                      >
                        <.icon name="hero-x-mark" class="w-3 h-3" />
                      </button>
                    </span>
                  <% end %>
                </div>
                <form phx-submit="add_tag" class="flex gap-2">
                  <input
                    type="text"
                    name="tag_name"
                    placeholder="Add tag..."
                    class="input input-sm flex-1"
                  />
                  <button type="submit" class="btn btn-sm btn-primary">
                    Add
                  </button>
                </form>
                <p class="text-xs text-base-content/60 mt-1">
                  {length(@image_tags)}/100 tags
                </p>
              </div>
            </div>
          </div>
        </div>
      <% end %>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    scope = socket.assigns.current_scope
    album = Gallery.get_album_with_images!(scope, id)
    album_share = Gallery.get_album_share(album)
    available_images = Gallery.list_images_not_in_album(album)
    grouped_images = Gallery.group_images_by_source(available_images)

    {:ok,
     socket
     |> assign(:page_title, album.name)
     |> assign(:album, album)
     |> assign(:album_share, album_share)
     |> assign(:available_images, available_images)
     |> assign(:grouped_images, grouped_images)
     |> assign(:collapsed_groups, MapSet.new())
     |> assign(:selected_image, nil)
     |> assign(:details_image, nil)
     |> assign(:details_form, nil)
     |> assign(:image_tags, [])
     |> assign(:selected_tag_ids, MapSet.new())
     |> assign(:all_tags, Gallery.list_tags(scope))}
  end

  @impl true
  def handle_params(_params, uri, socket) do
    # Store current path for OAuth return redirect
    %URI{path: path} = URI.parse(uri)
    {:noreply, assign(socket, :current_path, path)}
  end

  @impl true
  def handle_event("toggle_share", _, socket) do
    album = socket.assigns.album

    case Gallery.toggle_album_share(album) do
      {:ok, %Gallery.AlbumShare{is_active: true} = share} ->
        {:noreply, assign(socket, :album_share, share)}

      {:ok, %Gallery.AlbumShare{is_active: false}} ->
        {:noreply, assign(socket, :album_share, nil)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to update sharing")}
    end
  end

  def handle_event("open_lightbox", %{"image-id" => image_id}, socket) do
    image = Gallery.get_image!(image_id)
    {:noreply, assign(socket, :selected_image, image)}
  end

  def handle_event("close_lightbox", _, socket) do
    {:noreply, assign(socket, :selected_image, nil)}
  end

  # ============================================================================
  # Image Details Modal
  # ============================================================================

  def handle_event("open_details", %{"image-id" => image_id}, socket) do
    image = Gallery.get_image!(image_id)
    tags = Gallery.list_tags_for_image(image)
    form = to_form(Gallery.Image.metadata_changeset(image, %{}))

    {:noreply,
     socket
     |> assign(:details_image, image)
     |> assign(:details_form, form)
     |> assign(:image_tags, tags)}
  end

  def handle_event("close_details", _, socket) do
    {:noreply,
     socket
     |> assign(:details_image, nil)
     |> assign(:details_form, nil)
     |> assign(:image_tags, [])}
  end

  def handle_event("validate_details", %{"image" => params}, socket) do
    image = socket.assigns.details_image
    changeset = Gallery.Image.metadata_changeset(image, params)
    {:noreply, assign(socket, :details_form, to_form(changeset, action: :validate))}
  end

  def handle_event("save_details", %{"image" => params}, socket) do
    image = socket.assigns.details_image

    case Gallery.update_image_metadata(image, params) do
      {:ok, updated_image} ->
        {:noreply,
         socket
         |> assign(:details_image, updated_image)
         |> assign(:details_form, to_form(Gallery.Image.metadata_changeset(updated_image, %{})))
         |> put_flash(:info, "Image details saved")}

      {:error, changeset} ->
        {:noreply, assign(socket, :details_form, to_form(changeset, action: :validate))}
    end
  end

  def handle_event("add_tag", %{"tag_name" => tag_name}, socket) when tag_name != "" do
    scope = socket.assigns.current_scope
    image = socket.assigns.details_image

    with {:ok, tag} <- Gallery.find_or_create_tag(scope, tag_name),
         {:ok, _} <- Gallery.add_tag_to_image(image, tag) do
      tags = Gallery.list_tags_for_image(image)
      {:noreply, assign(socket, :image_tags, tags)}
    else
      {:error, :tag_limit_reached} ->
        {:noreply, put_flash(socket, :error, "Maximum 100 tags per image")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to add tag")}
    end
  end

  def handle_event("add_tag", _, socket), do: {:noreply, socket}

  def handle_event("remove_tag", %{"tag-id" => tag_id}, socket) do
    image = socket.assigns.details_image
    scope = socket.assigns.current_scope
    tag = Gallery.get_tag!(scope, tag_id)

    Gallery.remove_tag_from_image(image, tag)
    tags = Gallery.list_tags_for_image(image)

    {:noreply, assign(socket, :image_tags, tags)}
  end

  # ============================================================================
  # Tag Filter
  # ============================================================================

  def handle_event("toggle_tag_filter", %{"tag-id" => tag_id}, socket) do
    tag_id = String.to_integer(tag_id)
    selected = socket.assigns.selected_tag_ids

    updated =
      if MapSet.member?(selected, tag_id) do
        MapSet.delete(selected, tag_id)
      else
        MapSet.put(selected, tag_id)
      end

    {:noreply, socket |> assign(:selected_tag_ids, updated) |> refresh_filtered_images()}
  end

  def handle_event("clear_tag_filter", _, socket) do
    {:noreply, socket |> assign(:selected_tag_ids, MapSet.new()) |> refresh_filtered_images()}
  end

  defp refresh_filtered_images(socket) do
    album = socket.assigns.album
    selected_tag_ids = socket.assigns.selected_tag_ids

    available_images =
      if MapSet.size(selected_tag_ids) == 0 do
        Gallery.list_images_not_in_album(album)
      else
        Gallery.list_images_not_in_album_filtered(album, MapSet.to_list(selected_tag_ids))
      end

    grouped_images = Gallery.group_images_by_source(available_images)

    socket
    |> assign(:available_images, available_images)
    |> assign(:grouped_images, grouped_images)
  end

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
