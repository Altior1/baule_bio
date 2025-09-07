defmodule BauleBioWeb.PageController do
  use BauleBioWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
