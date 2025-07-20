# This is the module where all the real crawling happens.
# the job of this module uis to go to a website, find all the links, then
# add that to the link store.
# This module will be created from the supervisor thread.
defmodule Skitter.CrawlerWorker do
  use Task

  alias Skitter.LinkStore
  alias HTTPoison
  alias Floki

  def start_link(url) do
    Task.start_link(fn -> crawl(url) end)
  end

  def crawl(url) do
    url = Skitter.Util.normalize_url(url)
    IO.puts("[Skitter] Crawling #{url}")

    request = Finch.build(:get, url, [], nil)

    case Finch.request(request, SkitterFinch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        base_uri = URI.parse(url)

        links =
          Floki.parse_document!(body)
          |> Floki.find("a[href]")
          |> Stream.map(&List.first(Floki.attribute(&1, "href")))
          |> Stream.filter(& &1)
          |> Enum.to_list()  # Must materialize before async_stream

        Task.async_stream(links, fn raw_link ->
          full_url =
            raw_link
            |> URI.parse()
            |> then(&URI.merge(base_uri, &1))
            |> URI.to_string()
            |> Skitter.Util.normalize_url()

          if Skitter.Util.allow_domain?(full_url) do
            LinkStore.add_link(full_url)
          end
        end,
          max_concurrency: 10,
          timeout: 1000
        )
        |> Stream.run()

        LinkStore.mark_visited(url)
        IO.puts("[Skitter] Finished #{url}")

      {:ok, %Finch.Response{status: status}} ->
        IO.puts("[Skitter] Skipped #{url} - HTTP #{status}")
        LinkStore.mark_visited(url)

      {:error, error} ->
        IO.puts("[Skitter] Error fetching #{url}: #{inspect(error)}")
    end
  end
end
