defmodule Skitter.CrawlerWorkerContentTypeTest do
  use ExUnit.Case, async: true

  test "content-type detection handles case variations" do
    headers1 = [{"content-type", "text/html; charset=utf-8"}]
    headers2 = [{"Content-Type", "application/json"}]

    html_ct = headers1 |> Enum.find_value(fn
      {"content-type", ct} -> ct
      {"Content-Type", ct} -> ct
      _ -> nil
    end)

    json_ct = headers2 |> Enum.find_value(fn
      {"content-type", ct} -> ct
      {"Content-Type", ct} -> ct
      _ -> nil
    end)

    assert is_binary(html_ct) and String.starts_with?(html_ct, "text/html")
    assert is_binary(json_ct) and not String.starts_with?(json_ct, "text/html")
  end
end
