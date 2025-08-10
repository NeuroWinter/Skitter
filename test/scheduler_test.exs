defmodule Skitter.SchedulerTest do
  use ExUnit.Case, async: false

  alias Skitter.{Scheduler, LinkStore, CrawlerSupervisor}

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

    # Ensure base domain is set and some seeds exist
    LinkStore.set_base_domain("https://example.com")
    :ets.insert(:skitter_links, {"https://example.com/a", :unvisited})
    :ets.insert(:skitter_links, {"https://example.com/b", :unvisited})

    {:ok, _pid} = Scheduler.start_link([])
    :ok
  end

  test "scheduler pulls unvisited and starts workers" do
    # We don't actually perform HTTP; just verify that items got marked inflight quickly
    :timer.sleep(150)
    inflight = LinkStore.inflight_count()
    assert inflight > 0
  end
end
