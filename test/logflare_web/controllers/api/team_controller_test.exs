defmodule LogflareWeb.Api.TeamControllerTest do
  use LogflareWeb.ConnCase

  import Logflare.Factory

  alias Logflare.Sources.Counters

  setup do
    insert(:plan, name: "Free")
    user = insert(:user)
    user_teams = insert_list(2, :team_user, team: insert(:team), email: user.email)

    teams = Enum.map(user_teams, & &1.team)
    Counters.start_link()

    {:ok, user: user, teams: teams}
  end

  describe "index/2" do
    test "returns list of teams for given user", %{conn: conn, user: user, teams: teams} do
      response =
        conn
        |> login_user(user)
        |> get("/api/teams")
        |> json_response(200)

      response = response |> Enum.map(& &1["name"]) |> Enum.sort()
      expected = teams |> Enum.map(& &1.name) |> Enum.sort()

      assert response == expected
    end
  end

  describe "show/2" do
    test "returns a single team given user and team token", %{
      conn: conn,
      user: user,
      teams: [team | _]
    } do
      response =
        conn
        |> login_user(user)
        |> get("/api/teams/#{team.token}")
        |> json_response(200)

      assert response["name"] == team.name
    end
  end
end
