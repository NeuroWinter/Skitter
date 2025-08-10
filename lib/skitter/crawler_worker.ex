# This is the module where all the real crawling happens.
# the job of this module uis to go to a website, find all the links, then
# add that to the link store.
# This module will be created from the supervisor thread.
defmodule Skitter.CrawlerWorker do
  use Task

  alias Skitter.LinkStore
  alias Floki

  def start_link(url) do
    Task.start_link(fn -> crawl(url) end)
  end

  def crawl(url) do
    url = Skitter.Util.normalize_url(url)
    # Debug logging removed for performance profiling

    headers = [
      {"user-agent", "Skitter/0.1 (+https://github.com/NeuroWinter/skitter)"},
      {"accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"}
    ]
    request = Finch.build(:get, url, headers, nil)

    case Finch.request(request, SkitterFinch, receive_timeout: 1_200, pool_timeout: 500) do
      {:ok, %Finch.Response{status: 200, headers: headers, body: body}} ->
        content_type =
          headers
          |> Enum.find_value(fn
            {"content-type", ct} -> ct
            {"Content-Type", ct} -> ct
            _ -> nil
          end)

        if is_binary(content_type) and not String.starts_with?(content_type, "text/html") do
          LinkStore.mark_visited(url)
          :ok
        else
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
          max_concurrency: 100,
          timeout: 3_000
        )
        |> Stream.run()

        LinkStore.mark_visited(url)
        end

      {:ok, %Finch.Response{status: status, headers: headers}} when status in 301..308 ->
        location =
          headers
          |> Enum.find_value(fn
            {"location", loc} -> loc
            {"Location", loc} -> loc
            _ -> nil
          end)

        if location do
          target =
            location
            |> URI.parse()
            |> then(&URI.merge(URI.parse(url), &1))
            |> URI.to_string()
            |> Skitter.Util.normalize_url()

          if Skitter.Util.allow_domain?(target) do
            LinkStore.add_link(target)
          end
        end
        LinkStore.mark_visited(url)

      {:ok, %Finch.Response{status: _status}} ->
        LinkStore.mark_visited(url)

      {:error, _error} ->
        LinkStore.mark_visited(url)
    end
  end
end
