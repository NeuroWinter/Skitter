defmodule Skitter.Scheduler do
  use GenServer

  alias Skitter.LinkStore
  alias Skitter.CrawlerSupervisor

  @interval 100
  @batch_size 100

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
      # No base domain set — stopping scheduler.
      {:stop, :normal, state}
    else
      unvisited = LinkStore.get_unvisited(@batch_size)

      if unvisited == [] do
        if LinkStore.has_inflight?() do
          # Wait for inflight workers to finish
          Process.send_after(self(), :tick, @interval)
          {:noreply, state}
        else
          # All work completed
          emit_done_event()
          Skitter.export_ffuf("ffuf_urls.txt")
          {:stop, :normal, state}
        end
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
    {:noreply, state}
  end

  defp schedule_next do
    Process.send_after(self(), :tick, @interval)
  end

  defp emit_done_event do
    :telemetry.execute(
      [:skitter, :crawl, :done],
      %{visited: LinkStore.visited_count(), inflight: LinkStore.inflight_count(), unvisited: LinkStore.unvisited_count()},
      %{}
    )
  end
end
