defmodule Skitter.CrawlerWorkerRedirectTest do
  use ExUnit.Case, async: true

  alias Skitter.CrawlerWorker

  test "redirect location is resolved against base URL" do
    url = "https://example.com/dir/page.html"
    location = "../other"

    target =
      location
      |> URI.parse()
      |> then(&URI.merge(URI.parse(url), &1))
      |> URI.to_string()

    assert target == "https://example.com/other"
  end
end
