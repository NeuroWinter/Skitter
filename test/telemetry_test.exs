defmodule Skitter.TelemetryTest do
  use ExUnit.Case, async: false

  alias Skitter.{LinkStore, Scheduler}

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

    # Set base and no work so scheduler finishes immediately
    LinkStore.set_base_domain("https://example.com")
    {:ok, _} = Scheduler.start_link([])

    :ok
  end

  test "emits crawl done telemetry when no work" do
    parent = self()

    :telemetry.attach(
      "test-done",
      [:skitter, :crawl, :done],
      fn _event, m, _meta, _cfg ->
        send(parent, {:done, m})
      end,
      nil
    )

    # Tick quickly
    send(Process.whereis(Scheduler), :tick)

    assert_receive {:done, m}, 1000
    assert Map.has_key?(m, :visited)
    assert Map.has_key?(m, :unvisited)
    assert Map.has_key?(m, :inflight)

    :telemetry.detach("test-done")
  end
end
