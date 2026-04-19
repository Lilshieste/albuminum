defmodule Albuminum.GooglePhotosPicker do
  @moduledoc """
  Client for Google Photos Picker API.
  Session-based photo selection through Google's picker UI.
  """

  @base_url "https://photospicker.googleapis.com/v1"

  @doc """
  Creates a picking session.
  Returns `pickerUri` (redirect user there) and session `id` (for polling).

  Options:
  - `:timeout` - Session timeout (default "600s")
  """
  def create_session(access_token, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, "600s")

    body = %{
      "pollingConfig" => %{"timeoutIn" => timeout}
    }

    "#{@base_url}/sessions"
    |> Req.post(json: body, auth: {:bearer, access_token})
    |> handle_response()
  end

  @doc """
  Polls session status.
  Returns `{:ready, body}` when user finished selecting, `{:pending, body}` otherwise.
  """
  def get_session_status(session_id, access_token) do
    "#{@base_url}/sessions/#{session_id}"
    |> Req.get(auth: {:bearer, access_token})
    |> case do
      {:ok, %Req.Response{status: 200, body: %{"mediaItemsSet" => true} = body}} ->
        {:ready, body}

      {:ok, %Req.Response{status: 200, body: body}} ->
        {:pending, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Lists media items selected in a session.
  Call after session status is `:ready`.

  Options:
  - `:page_size` - Items per page (default 100)
  - `:page_token` - Token for next page
  """
  def list_picked_items(session_id, access_token, opts \\ []) do
    params =
      [
        sessionId: session_id,
        pageSize: Keyword.get(opts, :page_size, 100),
        pageToken: Keyword.get(opts, :page_token)
      ]
      |> Enum.reject(fn {_, v} -> is_nil(v) end)

    "#{@base_url}/mediaItems"
    |> Req.get(params: params, auth: {:bearer, access_token})
    |> handle_response()
  end

  @doc """
  Deletes a session (cleanup).
  """
  def delete_session(session_id, access_token) do
    "#{@base_url}/sessions/#{session_id}"
    |> Req.delete(auth: {:bearer, access_token})
    |> case do
      {:ok, %Req.Response{status: status}} when status in [200, 204] ->
        :ok

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp handle_response({:ok, %Req.Response{status: 200, body: body}}) do
    {:ok, body}
  end

  defp handle_response({:ok, %Req.Response{status: 401}}) do
    {:error, :unauthorized}
  end

  defp handle_response({:ok, %Req.Response{status: 403, body: body}}) do
    require Logger
    Logger.error("Google Photos Picker 403 Forbidden: #{inspect(body)}")
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
