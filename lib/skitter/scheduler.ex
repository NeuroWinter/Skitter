defmodule Skitter.Scheduler do
  use GenServer

  alias Skitter.LinkStore
  alias Skitter.CrawlerSupervisor

  @interval 1_000
  @batch_size 10

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    schedule_next()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:tick, state) do
    if not LinkStore.has_seed?() do
      IO.puts("[Skitter] No base domain set — stopping scheduler.")
      {:stop, :normal, state}
    else
      unvisited = LinkStore.get_unvisited(@batch_size)

      if unvisited == [] do
        IO.puts("[Skitter] No more unvisited URLs. Stopping crawl.")
        Process.send_after(self(), :export_if_finished, 100)
        Skitter.export_ffuf("ffuf_urls.txt")
        {:stop, :normal, state}
      else
        Enum.each(unvisited, fn {url, _status} ->
          CrawlerSupervisor.start_crawler(url)
        end)

        Process.send_after(self(), :tick, @interval)
        {:noreply, state}
      end
    end
  end

  def handle_info(:export_if_finished, state) do
    if Skitter.LinkStore.empty?() do
      IO.puts("[Skitter] Exporting results to disk.")
      Skitter.LinkStore.export()
    end
    {:noreply, state}
  end

  defp schedule_next do
    Process.send_after(self(), :tick, @interval)
  end
end
