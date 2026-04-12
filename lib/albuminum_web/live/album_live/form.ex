defmodule AlbuminumWeb.AlbumLive.Form do
  use AlbuminumWeb, :live_view

  alias Albuminum.Gallery
  alias Albuminum.Gallery.Album

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage album records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="album-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Album</.button>
          <.button navigate={return_path(@return_to, @album)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    album = Gallery.get_album!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Album")
    |> assign(:album, album)
    |> assign(:form, to_form(Gallery.change_album(album)))
  end

  defp apply_action(socket, :new, _params) do
    album = %Album{}

    socket
    |> assign(:page_title, "New Album")
    |> assign(:album, album)
    |> assign(:form, to_form(Gallery.change_album(album)))
  end

  @impl true
  def handle_event("validate", %{"album" => album_params}, socket) do
    changeset = Gallery.change_album(socket.assigns.album, album_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"album" => album_params}, socket) do
    save_album(socket, socket.assigns.live_action, album_params)
  end

  defp save_album(socket, :edit, album_params) do
    case Gallery.update_album(socket.assigns.album, album_params) do
      {:ok, album} ->
        {:noreply,
         socket
         |> put_flash(:info, "Album updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, album))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_album(socket, :new, album_params) do
    case Gallery.create_album(socket.assigns.current_scope, album_params) do
      {:ok, album} ->
        {:noreply,
         socket
         |> put_flash(:info, "Album created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, album))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _album), do: ~p"/albums"
  defp return_path("show", album), do: ~p"/albums/#{album}"
end
