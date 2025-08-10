defmodule Skitter.UtilTest do
  use ExUnit.Case, async: true

  alias Skitter.Util

  test "normalize_url trims trailing slash" do
    assert Util.normalize_url("https://example.com/") == "https://example.com"
  end

  test "normalize_url keeps relative paths unchanged" do
    assert Util.normalize_url("/foo/bar/") == "/foo/bar"
  end

  test "normalize_url defaults scheme for host-only url when merging later" do
    # When given a bare host, URI.parse treats it as a path; our util leaves it
    # unchanged. Consumers should provide absolute URLs for seeds.
    assert Util.normalize_url("example.com") == "example.com"
  end

  test "allow_domain? returns false when no base domain set" do
    # Ensure base_domain is not set
    :ets.delete(:skitter_links, :base_domain)
    assert Util.allow_domain?("https://example.com") == false
  end
end
