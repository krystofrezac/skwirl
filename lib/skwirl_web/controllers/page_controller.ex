defmodule SkwirlWeb.PageController do
  use SkwirlWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
