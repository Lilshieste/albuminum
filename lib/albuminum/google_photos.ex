defmodule Albuminum.GooglePhotos do
  @moduledoc """
  Client for Google Photos Library API.
  Read-only access to user's photo library.
  """

  @base_url "https://photoslibrary.googleapis.com/v1"

  @doc """
  Lists albums from the user's Google Photos library.

  Options:
  - `:page_size` - Number of albums per page (default 50, max 50)
  - `:page_token` - Token for next page
  """
  def list_albums(access_token, opts \\ []) do
    page_size = Keyword.get(opts, :page_size, 50)
    page_token = Keyword.get(opts, :page_token)

    params =
      [pageSize: page_size, pageToken: page_token]
      |> Enum.reject(fn {_, v} -> is_nil(v) end)

    @base_url
    |> Kernel.<>("/albums")
    |> Req.get(auth: {:bearer, access_token}, params: params)
    |> handle_response()
  end

  @doc """
  Gets a single album by ID.
  """
  def get_album(access_token, album_id) do
    "#{@base_url}/albums/#{album_id}"
    |> Req.get(auth: {:bearer, access_token})
    |> handle_response()
  end

  @doc """
  Searches for media items (photos/videos).

  Options:
  - `:album_id` - Filter by album
  - `:page_size` - Items per page (default 100, max 100)
  - `:page_token` - Token for next page
  """
  def search_media_items(access_token, opts \\ []) do
    body =
      %{
        albumId: opts[:album_id],
        pageSize: opts[:page_size] || 100,
        pageToken: opts[:page_token]
      }
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new()

    "#{@base_url}/mediaItems:search"
    |> Req.post(auth: {:bearer, access_token}, json: body)
    |> handle_response()
  end

  @doc """
  Gets a single media item by ID.
  """
  def get_media_item(access_token, media_item_id) do
    "#{@base_url}/mediaItems/#{media_item_id}"
    |> Req.get(auth: {:bearer, access_token})
    |> handle_response()
  end

  @doc """
  Lists all media items in the library.

  Options:
  - `:page_size` - Items per page (default 100, max 100)
  - `:page_token` - Token for next page
  """
  def list_media_items(access_token, opts \\ []) do
    page_size = Keyword.get(opts, :page_size, 100)
    page_token = Keyword.get(opts, :page_token)

    params =
      [pageSize: page_size, pageToken: page_token]
      |> Enum.reject(fn {_, v} -> is_nil(v) end)

    "#{@base_url}/mediaItems"
    |> Req.get(auth: {:bearer, access_token}, params: params)
    |> handle_response()
  end

  defp handle_response({:ok, %Req.Response{status: 200, body: body}}) do
    {:ok, body}
  end

  defp handle_response({:ok, %Req.Response{status: 401}}) do
    {:error, :unauthorized}
  end

  defp handle_response({:ok, %Req.Response{status: 403}}) do
    {:error, :forbidden}
  end

  defp handle_response({:ok, %Req.Response{status: 429}}) do
    {:error, :rate_limited}
  end

  defp handle_response({:ok, %Req.Response{status: status, body: body}}) do
    {:error, {status, body}}
  end

  defp handle_response({:error, reason}) do
    {:error, reason}
  end
end
