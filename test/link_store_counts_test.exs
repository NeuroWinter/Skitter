defmodule Skitter.LinkStoreCountsTest do
  use ExUnit.Case, async: false

  alias Skitter.LinkStore

  setup do
    # Clear ETS tables
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

  test "visited_count, unvisited_count, inflight_count reflect ETS" do
    :ets.insert(:skitter_links, {"https://e/a", :visited})
    :ets.insert(:skitter_links, {"https://e/b", {:visited, 1}})
    :ets.insert(:skitter_links, {"https://e/c", :unvisited})
    :ets.insert(:skitter_links, {"https://e/d", :inflight})
    :ets.insert(:skitter_inflight, {"https://e/d", 123})

    assert LinkStore.visited_count() == 2
    assert LinkStore.unvisited_count() == 1
    assert LinkStore.inflight_count() == 1
    assert LinkStore.has_inflight?()
  end
end
