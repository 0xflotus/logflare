defmodule LogflareWeb.Api.TeamController do
  use LogflareWeb, :controller
  alias Logflare.Teams
  action_fallback LogflareWeb.Api.FallbackController

  def index(%{assigns: %{user: user}} = conn, _) do
    teams = Teams.list_for_user(user)
    json(conn, teams)
  end

  def show(%{assigns: %{user: user}} = conn, %{"token" => token}) do
    team = Teams.get(user, token)
    json(conn, team)
  end

  # def create(%{assigns: %{user: user}} = conn, params) do
  #   :ok
  # end

  # def update(%{assigns: %{user: user}} = conn, %{"token" => token} = params) do
  #   :ok
  # end

  # def delete(%{assigns: %{user: user}} = conn, %{"token" => token}) do
  #   :ok
  # end
end
