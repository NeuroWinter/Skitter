defmodule Skitter.ExportDedupSortTest do
  use ExUnit.Case, async: false

  setup do
    # Clear ETS and prepare
    for {tab, keymatch} <- [
          {:skitter_links, :_},
          {:skitter_inflight, :_}
        ] do
      case :ets.whereis(tab) do
        :undefined -> :ok
        tid -> :ets.select_delete(tid, [{{keymatch, :_}, [], [true]}])
      end
    end

    on_exit(fn -> File.rm_rf!("tmp_export") end)
    :ok
  end

  test "export sorts and deduplicates" do
    :ets.insert(:skitter_links, {"https://b.com/2", :visited})
    :ets.insert(:skitter_links, {"https://a.com/1", :visited})
    :ets.insert(:skitter_links, {"https://a.com/1", {:visited, 3}})
    :ets.insert(:skitter_links, {"https://c.com/3", :unvisited})

    File.mkdir_p!("tmp_export")
    out = Path.join("tmp_export", "ffuf_urls.txt")
    Skitter.export_ffuf(out)

    {:ok, contents} = File.read(out)
    assert contents == "https://a.com/1\nhttps://b.com/2"
  end
end
