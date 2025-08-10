defmodule Skitter.UtilMoreTest do
  use ExUnit.Case, async: true

  alias Skitter.Util

  test "normalize_url trims spaces" do
    assert Util.normalize_url("  https://example.com  ") == "https://example.com"
  end

  test "normalize_url keeps anchor-only and query-only as-is for merging" do
    assert Util.normalize_url("#frag") == "#frag"
    assert Util.normalize_url("?q=1") == "?q=1"
  end

  test "allow_domain? true only for base domain" do
    # No base domain -> false
    assert Util.allow_domain?("https://example.com") == false

    # Set base and test
    :ets.insert(:skitter_links, {:base_domain, "example.com"})
    assert Util.allow_domain?("https://example.com/path") == true
    assert Util.allow_domain?("https://sub.example.com") == false
    assert Util.allow_domain?("https://other.com") == false
  end
end
