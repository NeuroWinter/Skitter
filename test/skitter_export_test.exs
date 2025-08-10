defmodule Skitter.ExportTest do
  use ExUnit.Case, async: false

  alias Skitter.LinkStore

  setup do
    # clear tables
    for {tab, keymatch} <- [
          {:skitter_links, :_},
          {:skitter_inflight, :_}
        ] do
      case :ets.whereis(tab) do
        :undefined -> :ok
        tid -> :ets.select_delete(tid, [{{keymatch, :_}, [], [true]}])
      end
    end

    on_exit(fn ->
      File.rm_rf!("tmp_test")
    end)

    :ok
  end

  test "export_ffuf writes only visited URLs sorted and unique" do
    # Seed ETS
    :ets.insert(:skitter_links, {"https://example.com/a", :visited})
    :ets.insert(:skitter_links, {"https://example.com/b", :visited})
    :ets.insert(:skitter_links, {"https://example.com/b", {:visited, 1}})
    :ets.insert(:skitter_links, {"https://example.com/c", :unvisited})

    File.mkdir_p!("tmp_test")
    out = Path.join("tmp_test", "ffuf_urls.txt")
    Skitter.export_ffuf(out)

    {:ok, contents} = File.read(out)
    lines = contents |> String.split("\n", trim: true)
    assert lines == [
             "https://example.com/a",
             "https://example.com/b"
           ]
  end
end
