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

    case HTTPoison.get(url, [], follow_redirect: true) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        links =
          Floki.parse_document!(body)
          |> Floki.find("a[href]")
          |> Enum.map(&Floki.attribute(&1, "href") |> List.first())
          |> Enum.filter(& &1)

        # here we need to make sure that we are adding the full url to the link store.
        base_uri = URI.parse(url)
        Enum.each(links, fn raw_link ->
          full_url =
            raw_link
            |> URI.parse()
            |> then(&URI.merge(base_uri, &1))
            |> URI.to_string()
            |> Skitter.Util.normalize_url()

          if Skitter.Util.allow_domain?(full_url) do
            LinkStore.add_link(full_url)
          end
        end)

        LinkStore.mark_visited(url)

        IO.puts("[Skitter] Found #{length(links)} links at #{url}")

      {:ok, %HTTPoison.Response{status_code: status}} ->
        IO.puts("[Skitter] Skipped #{url} - HTTP #{status}")
        LinkStore.mark_visited(url)

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.puts("[Skitter] Error fetching #{url}: #{inspect(reason)}")
    end
  end
end
