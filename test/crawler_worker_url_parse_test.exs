defmodule Skitter.CrawlerWorkerURLParseTest do
  use ExUnit.Case, async: true

  test "URI.merge builds absolute URLs from relative" do
    base = URI.parse("https://example.com/path/index.html")

    assert base |> URI.merge(URI.parse("/about")) |> URI.to_string() == "https://example.com/about"
    assert base |> URI.merge(URI.parse("faq.html")) |> URI.to_string() == "https://example.com/path/faq.html"
    assert base |> URI.merge(URI.parse("../up")) |> URI.to_string() == "https://example.com/up"
  end
end
