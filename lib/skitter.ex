defmodule Skitter do
  @moduledoc """
  Public API for the Skitter web crawler.
  """

  alias Skitter.LinkStore
  alias Skitter.CrawlerSupervisor

  @doc """
  Sets the base domain and seeds the crawler with a starting URL.
  """
  def set_seed(seed_url) when is_binary(seed_url) do
    seed_url = Skitter.Util.normalize_url(seed_url)

    LinkStore.set_base_domain(seed_url)
    LinkStore.add_link(seed_url)
    CrawlerSupervisor.start_crawler(seed_url)
    case Process.whereis(Skitter.Scheduler) do
      nil ->
        Skitter.Scheduler.start_link([])

      _pid ->
        :ok
    end
  end

  def export_ffuf(path \\ "ffuf_urls.txt") do
    urls =
      LinkStore.all()
      |> Enum.filter(fn
        {url, :visited} -> true
        {url, {:visited, _depth}} -> true
        _ -> false
      end)
      |> Enum.map(&elem(&1, 0))
      |> Enum.uniq()
      |> Enum.sort()

    File.write!(path, Enum.join(urls, "\n"))
    IO.puts("[Skitter] Exported #{length(urls)} URLs to #{path}")
  end
end
