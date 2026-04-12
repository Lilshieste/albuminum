defmodule AlbuminumWeb.PageController do
  use AlbuminumWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
