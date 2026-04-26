defmodule AlbuminumWeb.Live.Components.GooglePhotosBrowser do
  @moduledoc """
  LiveComponent for selecting photos via Google Photos Picker.
  Opens Google's picker UI in popup, polls for completion, imports selected photos.
  """

  use AlbuminumWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div id="google-photos-picker" phx-hook="PhotoPicker" class="border-t pt-8 mt-8">
      <h2 class="text-lg font-semibold mb-4">Import from Google Photos</h2>

      <%= case @status do %>
        <% :not_connected -> %>
          <div class="text-center py-8 bg-base-200 rounded-lg">
            <p class="text-base-content/70 mb-4">Connect your Google account to import photos</p>
            <.link href={~p"/auth/google/photos?#{[return_to: @current_path]}"} class="btn btn-primary">
              <svg class="size-5 mr-2" viewBox="0 0 24 24">
                <path fill="#fff" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                <path fill="#fff" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                <path fill="#fff" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                <path fill="#fff" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
              </svg>
              Connect Google Photos
            </.link>
          </div>

        <% :idle -> %>
          <div class="text-center py-8 bg-base-200 rounded-lg">
            <p class="text-base-content/70 mb-4">Select photos from your Google Photos library</p>
            <button phx-click="start_picker" phx-target={@myself} class="btn btn-primary">
              <svg class="size-5 mr-2" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="3" y="3" width="18" height="18" rx="2" ry="2"/>
                <circle cx="8.5" cy="8.5" r="1.5"/>
                <polyline points="21 15 16 10 5 21"/>
              </svg>
              Select from Google Photos
            </button>
          </div>

        <% :polling -> %>
          <div class="text-center py-8 bg-base-200 rounded-lg">
            <div class="flex items-center justify-center gap-3 mb-4">
              <span class="loading loading-spinner loading-md"></span>
              <p class="text-base-content/70">Waiting for you to select photos...</p>
            </div>
            <p class="text-sm text-base-content/50">
              A Google Photos window should have opened. Select your photos and click "Done".
            </p>
          </div>

        <% :importing -> %>
          <div class="text-center py-8 bg-base-200 rounded-lg">
            <div class="flex items-center justify-center gap-3">
              <span class="loading loading-spinner loading-md"></span>
              <p class="text-base-content/70">Importing {@import_count} photos...</p>
            </div>
          </div>

        <% :error -> %>
          <div class="alert alert-error">
            <span>{@error_message}</span>
            <button phx-click="reset_picker" phx-target={@myself} class="btn btn-sm">
              Try Again
            </button>
          </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:status, :idle)
     |> assign(:import_count, 0)
     |> assign(:error_message, nil)}
  end

  @impl true
  def update(assigns, socket) do
    socket = assign(socket, assigns)

    if socket.assigns[:status] == :idle && is_nil(socket.assigns[:checked_connection]) do
      send(self(), {:check_google_connection, socket.assigns.id})
      socket = assign(socket, :checked_connection, true)
      {:ok, socket}
    else
      {:ok, socket}
    end
  end

  @impl true
  def handle_event("start_picker", _, socket) do
    send(self(), {:start_photo_picker, socket.assigns.id, socket.assigns.album.id})
    {:noreply, socket}
  end

  def handle_event("reset_picker", _, socket) do
    {:noreply,
     socket
     |> assign(:status, :idle)
     |> assign(:error_message, nil)}
  end
end
