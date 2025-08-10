defmodule Skitter.LinkStoreTest do
  use ExUnit.Case, async: false

  alias Skitter.LinkStore

  setup do
    # Clear tables if they already exist
    for {tab, keymatch} <- [
          {:skitter_links, :_},
          {:skitter_inflight, :_}
        ] do
      case :ets.whereis(tab) do
        :undefined -> :ok
        tid -> :ets.select_delete(tid, [{{keymatch, :_}, [], [true]}])
      end
    end

    :ok
  end

  test "add_link inserts unvisited when not present" do
    LinkStore.add_link("https://example.com")
    LinkStore.flush()
    assert [{"https://example.com", :unvisited}] = :ets.lookup(:skitter_links, "https://example.com")
  end

  test "add_link is idempotent and does not overwrite status" do
    :ets.insert(:skitter_links, {"https://example.com/a", :visited})
    LinkStore.add_link("https://example.com/a")
    LinkStore.flush()
    assert [{"https://example.com/a", :visited}] = :ets.lookup(:skitter_links, "https://example.com/a")
  end

  test "get_unvisited marks returned URLs as inflight" do
    :ets.insert(:skitter_links, {"https://example.com/1", :unvisited})
    :ets.insert(:skitter_links, {"https://example.com/2", :unvisited})

    urls = LinkStore.get_unvisited(1)
    assert length(urls) == 1
    {picked_url, status} = hd(urls)
    assert status == :inflight
    assert picked_url in ["https://example.com/1", "https://example.com/2"]

    # Ensure table status updated
    for {url, _} <- urls do
      assert [{^url, :inflight}] = :ets.lookup(:skitter_links, url)
      assert [{^url, _ts}] = :ets.lookup(:skitter_inflight, url)
    end

    assert LinkStore.inflight_count() == 1
  end

  test "mark_visited sets status and clears inflight" do
    :ets.insert(:skitter_links, {"https://example.com/x", :inflight})
    :ets.insert(:skitter_inflight, {"https://example.com/x", 1})

    LinkStore.mark_visited("https://example.com/x")
    assert [{"https://example.com/x", :visited}] = :ets.lookup(:skitter_links, "https://example.com/x")
    assert [] = :ets.lookup(:skitter_inflight, "https://example.com/x")
  end

  test "set_base_domain and get_base_domain" do
    LinkStore.set_base_domain("https://sub.example.com/path")
    assert "sub.example.com" == LinkStore.get_base_domain()
  end

  test "has_seed? true when base_domain present" do
    :ets.insert(:skitter_links, {:base_domain, "example.com"})
    assert LinkStore.has_seed?()
  end
end
