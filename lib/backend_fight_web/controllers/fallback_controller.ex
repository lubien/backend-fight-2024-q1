defmodule BackendFightWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use BackendFightWeb, :controller

  # This clause handles errors returned by Ecto's insert/update/delete.
  def call(conn, {:error, %Ecto.Changeset{}}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(html: BackendFightWeb.ErrorHTML, json: BackendFightWeb.ErrorJSON)
    |> render(:"422")
  end

  def call(conn, {:error, :unprocessable_entity}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(html: BackendFightWeb.ErrorHTML, json: BackendFightWeb.ErrorJSON)
    |> render(:"422")
  end

  # This clause is an example of how to handle resources that cannot be found.
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(html: BackendFightWeb.ErrorHTML, json: BackendFightWeb.ErrorJSON)
    |> render(:"404")
  end
end
