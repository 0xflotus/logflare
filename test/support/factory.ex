defmodule Logflare.Factory do
  @moduledoc """
  Generates fixtures for schemas
  """
  use ExMachina.Ecto, repo: Logflare.Repo

  alias Logflare.TestUtils
  alias Logflare.Backends.SourceBackend
  alias Logflare.Billing.BillingAccount
  alias Logflare.Billing.PaymentMethod
  alias Logflare.Billing.Plan
  alias Logflare.Endpoints.Query
  alias Logflare.LogEvent
  alias Logflare.Lql
  alias Logflare.OauthAccessTokens.OauthAccessToken
  alias Logflare.Rule
  alias Logflare.Source
  alias Logflare.Teams.Team
  alias Logflare.TeamUsers.TeamUser
  alias Logflare.User
  alias Logflare.Users.UserPreferences

  def user_factory do
    email = "#{TestUtils.random_string(8)}@#{TestUtils.random_string()}.com"

    %User{
      name: "JaneJohn Jones",
      email: email,
      email_preferred: email,
      provider: "google",
      bigquery_processed_bytes_limit: 10_000_000_000,
      token: TestUtils.random_string(64),
      api_key: TestUtils.random_string(10),
      provider_uid: "provider_uid",
      bigquery_udfs_hash: ""
    }
  end

  def team_factory do
    %Team{
      name: "my team #{TestUtils.random_string()}",
      user: build(:user)
    }
  end

  def team_user_factory do
    %TeamUser{
      name: "some name #{TestUtils.random_string()}",
      team: build(:team)
    }
  end

  def source_factory do
    %Source{
      name: TestUtils.random_string(10),
      token: TestUtils.gen_uuid(),
      rules: [],
      favorite: false,
      metrics: %{
        avg: 0
      }
    }
  end

  def source_backend_factory do
    %SourceBackend{
      type: :bigquery
    }
  end

  def rule_factory(attrs) do
    lql = Map.get(attrs, "lql_string", "testing")
    {:ok, lql_filters} = Lql.Parser.parse(lql, TestUtils.default_bq_schema())

    %Rule{
      regex: attrs[:regex],
      lql_string: lql,
      lql_filters: lql_filters,
      sink: attrs[:sink],
      source_id: attrs[:source_id]
    }
  end

  def log_event_factory(attrs) do
    {source, params} = Map.pop(attrs, :source)

    params = %{
      "message" => params["message"] || params[:message] || "test-msg",
      "timestamp" => params["timestamp"] || params[:timestamp] || DateTime.utc_now() |> to_string,
      "metadata" => params["metadata"] || params[:metadata] || %{}
    }

    LogEvent.make(params, %{source: source})
  end

  def plan_factory() do
    %Plan{
      stripe_id: "31415",
      price: 0,
      period: "month",
      name: "Free"
    }
  end

  def billing_account_factory(attrs) do
    stripe_plan_id = Map.get(attrs, :stripe_plan_id, "some plan id #{TestUtils.random_string()}")

    stripe_sub_item_id =
      Map.get(attrs, :stripe_subscription_item_id, "some sub id #{TestUtils.random_string()}")

    attrs =
      attrs
      |> Map.delete(:stripe_plan_id)
      |> Map.delete(:stripe_subscription_item_id)

    %BillingAccount{
      user: build(:user),
      stripe_customer: TestUtils.random_string(10),
      stripe_subscriptions: %{
        "data" => [
          %{
            "plan" => %{"id" => stripe_plan_id},
            "items" => %{
              "data" => [%{"id" => stripe_sub_item_id}]
            }
          }
        ]
      }
    }
    |> merge_attributes(attrs)
  end

  def payment_method_factory(attrs) do
    customer_id = Map.get(attrs, :customer_id)

    customer_id =
      if customer_id == nil do
        ba = build(:billing_account)
        Map.get(ba, :stripe_customer)
      else
        customer_id
      end

    %PaymentMethod{
      stripe_id: "stripe_#{TestUtils.random_string()}",
      customer_id: customer_id,
      price_id: "price_#{TestUtils.random_string()}"
    }
    |> merge_attributes(attrs)
  end

  @spec user_preferences_factory :: Logflare.Users.UserPreferences.t()
  def user_preferences_factory() do
    %UserPreferences{
      timezone: "Phoenix/Arizona"
    }
  end

  def endpoint_factory do
    %Query{
      user: build(:user),
      token: Ecto.UUID.generate(),
      query: "select current_date() as date",
      name: TestUtils.random_string()
    }
  end

  def access_token_factory do
    %OauthAccessToken{
      token: TestUtils.random_string(20),
      resource_owner: build(:user)
    }
  end
end
