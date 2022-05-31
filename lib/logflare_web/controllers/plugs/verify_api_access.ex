defmodule LogflareWeb.Plugs.VerifyApiAccess do
  @moduledoc """
  Verifies if a user has access to a requested resource.

  Assigns the token's associated user if the token is provided
  """
  import Plug.Conn
  import Phoenix.Controller
  alias Logflare.Auth
  alias Logflare.{Endpoint}

  def init(_), do: nil

  def call(%{request_path: "/endpoints/query" <> _} = conn, _) do
    do_auth(:endpoints, conn)
  end

  def call(%{request_path: _} = conn) do
    do_auth(nil, conn)
  end

  defp do_auth(:endpoints, conn) do
    conn = fetch_query_params(conn)
    # fetch endpoint info
    with endpoint_token <- conn.params["token"],
         %Endpoint.Query{enable_auth: true, user_id: user_id} <-
           Logflare.Endpoint.get_query_by_token(endpoint_token),
         {:ok, token} <- extract_token(conn),
         {:ok, user} <- Auth.verify_access_token(token),
         true <- user_id == user.id do
      assign(conn, :user, user)
    else
      %Endpoint.Query{enable_auth: false} ->
        conn

      _ ->
        send_error_response(conn, 401, "Error: Unauthorized")
    end
  end

  defp do_auth(_resource, conn) do
    # unknown resource, reject as bad request
    send_error_response(conn, 400, "Error: Bad request")
  end

  defp extract_token(conn) do
    auth_header =
      conn.req_headers
      |> Enum.into(%{})
      |> Map.get("authorization")

    bearer =
      if auth_header && String.contains?(auth_header, "Bearer ") do
        String.split(auth_header, " ")
        |> Enum.at(1)
      end

    api_key =
      conn.req_headers
      |> Enum.into(%{})
      |> Map.get("x-api-key", conn.params["api_key"])

    cond do
      bearer != nil -> {:ok, bearer}
      api_key != nil -> {:ok, api_key}
      true -> {:error, :no_token}
    end
  end

  defp send_error_response(conn, code, message) do
    conn
    |> put_status(code)
    |> put_view(LogflareWeb.LogView)
    |> render("index.json", message: message)
    |> halt()
  end
end