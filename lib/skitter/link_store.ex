defmodule Skitter.LinkStore do
  use GenServer

  @table :skitter_links
  @inflight_table :skitter_inflight

  ## PUBLIC API
  # These are the functions that I can call from outside.

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def add_link(link) when is_binary(link) do
    link = Skitter.Util.normalize_url(link)
    GenServer.cast(__MODULE__, {:add_link, link})
  end

  # Test helper: synchronously wait until casts are processed
  def flush do
    GenServer.call(__MODULE__, :flush)
  end

  def mark_visited(link) when is_binary(link) do
    link = Skitter.Util.normalize_url(link)
    :ets.insert(@table, {link, :visited})
    :ets.delete(@inflight_table, link)
  end

  def get_unvisited(limit \\ 10) do
    candidates =
      :ets.select(@table, [
        {{:"$1", :unvisited}, [], [:"$1"]}
      ])
      |> Enum.take(limit)

    Enum.each(candidates, fn url ->
      :ets.insert(@inflight_table, {url, System.monotonic_time()})
      :ets.insert(@table, {url, :inflight})
    end)

    Enum.map(candidates, &{&1, :inflight})
  end

  def all do
    :ets.tab2list(@table)
  end

  def unvisited_count do
    :ets.select_count(@table, [
      {{:"$1", :unvisited}, [], [true]}
    ])
  end

  def inflight_count do
    :ets.select_count(@inflight_table, [
      {{:"$1", :"$2"}, [], [true]}
    ])
  end

  def has_inflight?, do: inflight_count() > 0

  def visited_count do
    :ets.select_count(@table, [
      {{:"$1", :visited}, [], [true]},
      {{:"$1", {:visited, :"$2"}}, [], [true]}
    ])
  end

  # At the start I want to save the base domain here, so that I can refer to it
  # later when there are relative links.
  def set_base_domain(url) do
    base_host =
      url
      |> URI.parse()
      |> Map.get(:host)

    if base_host, do: :ets.insert(@table, {:base_domain, base_host})
  end

  # This will get called when I am trying to add the domain to realitive links.
  def get_base_domain do
    case :ets.lookup(@table, :base_domain) do
      [{:base_domain, host}] -> host
      _ -> nil
    end
  end

  def has_seed? do
    case :ets.lookup(:skitter_links, :base_domain) do
      [{:base_domain, _}] -> true
      _ -> false
    end
  end

  def empty? do
    Agent.get(__MODULE__, fn %{queue: queue} -> :queue.is_empty(queue) end)
  end

  ## SERVER CALLBACKS

  @impl true
  def init(:ok) do
    if :ets.whereis(@table) == :undefined do
      :ets.new(@table, [:set, :named_table, :public, read_concurrency: true])
    end

    if :ets.whereis(@inflight_table) == :undefined do
      :ets.new(@inflight_table, [:set, :named_table, :public, read_concurrency: true])
    end

    {:ok, %{}}
  end

  @impl true
  def handle_cast({:add_link, link}, state) do
    # Avoid duplicates; do not overwrite inflight/visited
    case :ets.lookup(@table, link) do
      [] -> :ets.insert(@table, {link, :unvisited})
      _ -> :ok
    end

    {:noreply, state}
  end

  @impl true
  def handle_call(:flush, _from, state) do
    {:reply, :ok, state}
  end
end
