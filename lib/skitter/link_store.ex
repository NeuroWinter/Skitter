defmodule Skitter.LinkStore do
  use GenServer

  @table :skitter_links

  ## PUBLIC API
  # These are the functions that I can call from outside.

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def add_link(link) when is_binary(link) do
    link = Skitter.Util.normalize_url(link)
    GenServer.cast(__MODULE__, {:add_link, link})
  end

  def mark_visited(link) when is_binary(link) do
    link = Skitter.Util.normalize_url(link)
    :ets.insert(@table, {link, :visited})
  end

  def get_unvisited(limit \\ 10) do
    :ets.tab2list(@table)
    |> Enum.filter(fn {_url, status} -> status == :unvisited end)
    |> Enum.take(limit)
  end

  def all do
    :ets.tab2list(@table)
  end

  # at the start I want to save the base domain here, so that I can refer to it
  # later when there are ralitive links.
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

    {:ok, %{}}
  end

  @impl true
  def handle_cast({:add_link, link}, state) do
    # we want to just add the link to the ets if its not already there.
    # No need to reply.
    if :ets.lookup(@table, link) == [] do
      :ets.insert(@table, {link, :unvisited})
    end

    {:noreply, state}
  end
end
