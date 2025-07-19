# this is the module that looks over and creates all the workers that will
# crawl the site.
defmodule Skitter.CrawlerSupervisor do
  use DynamicSupervisor

  def start_link(_opts) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_crawler(url) do
    child_spec = %{
      id: Skitter.CrawlerWorker,
      start: {Skitter.CrawlerWorker, :start_link, [url]},
      restart: :temporary
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end
end
