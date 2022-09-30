defmodule Logflare.Teams.Team do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "teams" do
    field :name, :string
    belongs_to :user, Logflare.User
    has_many :team_users, Logflare.TeamUsers.TeamUser

    timestamps()
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
