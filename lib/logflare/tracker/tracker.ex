defmodule Logflare.Tracker do
  @moduledoc false
  @behaviour Phoenix.Tracker

  require Logger

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 1_000
    }
  end

  def start_link(opts) do
    opts = Keyword.merge([name: __MODULE__], opts)
    Phoenix.Tracker.start_link(__MODULE__, opts, opts)
  end

  def init(opts) do
    server = Keyword.fetch!(opts, :pubsub_server)
    {:ok, %{pubsub_server: server, node_name: Phoenix.PubSub.node_name(server)}}
  end

  def handle_diff(_diff, state) do
    {:ok, state}
  end

  def update(tracker_name, pid, topic, key, meta) do
    try do
      Phoenix.Tracker.update(tracker_name, pid, topic, key, meta)
    catch
      :exit, _ -> Logger.warn("Tracker.update timeout!")
    end
  end

  def track(tracker_name, pid, topic, key, meta) do
    try do
      Phoenix.Tracker.track(tracker_name, pid, topic, key, meta)
    catch
      :exit, _ -> Logger.warn("Tracker.track timeout!")
    end
  end

  def list(tracker_name, topic) do
    Phoenix.Tracker.list(tracker_name, topic)
  end

  def dirty_list(tracker_name, topic) do
    pool_size = Application.get_env(:logflare, __MODULE__)[:pool_size]

    tracker_name
    |> Phoenix.Tracker.Shard.name_for_topic(topic, pool_size)
    |> Phoenix.Tracker.Shard.dirty_list(topic)
  end
end
