defmodule AlbuminumWeb.AlbumLive.Index do
  use AlbuminumWeb, :live_view

  alias Albuminum.Gallery

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Albums
        <:actions>
          <.button variant="primary" navigate={~p"/albums/new"}>
            <.icon name="hero-plus" /> New Album
          </.button>
        </:actions>
      </.header>

      <.table
        id="albums"
        rows={@streams.albums}
        row_click={fn {_id, album} -> JS.navigate(~p"/albums/#{album}") end}
      >
        <:col :let={{_id, album}} label="Name">{album.name}</:col>
        <:col :let={{_id, album}} label="Description">{album.description}</:col>
        <:action :let={{_id, album}}>
          <div class="sr-only">
            <.link navigate={~p"/albums/#{album}"}>Show</.link>
          </div>
          <.link navigate={~p"/albums/#{album}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, album}}>
          <.link
            phx-click={JS.push("delete", value: %{id: album.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Albums")
     |> stream(:albums, list_albums())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    album = Gallery.get_album!(id)
    {:ok, _} = Gallery.delete_album(album)

    {:noreply, stream_delete(socket, :albums, album)}
  end

  defp list_albums() do
    Gallery.list_albums()
  end
end
