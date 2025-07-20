defmodule Skitter.Application do
  use Application

  def start(_type, _args) do
    children = [
      Skitter.LinkStore,
      {DynamicSupervisor, strategy: :one_for_one, name: Skitter.CrawlerSupervisor},
      {Finch, name: SkitterFinch, pools: %{
        default: [protocols: [:http2, :http1]]
      }}
    ]
    #Skitter.FinchTelemetry.attach()
    #Skitter.MintTelemetry.attach()
    Supervisor.start_link(children, strategy: :one_for_one, name: Skitter.Supervisor)
  end
end


defmodule Skitter.FinchTelemetry do
  require Logger

  def attach do
    :telemetry.attach_many(
      "skitter-finch-telemetry",
      [
        [:finch, :request, :start],
        [:finch, :request, :stop],
        [:finch, :request, :exception]
      ],
      &__MODULE__.handle_event/4,
      nil
    )
  end

  def handle_event([:finch, :request, :start], _measurements, metadata, _config) do
    Logger.debug("[Finch] Starting request to #{metadata.request.host}")
  end

  def handle_event([:finch, :request, :stop], measurements, metadata, _config) do
    duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)
    Logger.info("[Finch] Finished request to #{metadata.request.host} in #{duration_ms}ms")
  end

  def handle_event([:finch, :request, :exception], measurements, metadata, _config) do
    duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)
    Logger.error("[Finch] Request to #{metadata.request.host} failed in #{duration_ms}ms")
  end
end

defmodule Skitter.MintTelemetry do
  require Logger

  def attach do
    :telemetry.attach_many(
      "skitter-mint-telemetry",
      [
        [:mint, :transport, :connect, :stop],
        [:mint, :http, :request, :start],
        [:mint, :http, :request, :stop],
        [:mint, :http, :response, :stop],
        [:mint, :http, :error]
      ],
      &__MODULE__.handle_event/4,
      nil
    )
  end

  def handle_event([:mint, :transport, :connect, :stop], m, md, _) do
    duration = System.convert_time_unit(m.duration, :native, :millisecond)
    Logger.info("[Mint] Connected to #{md.host}:#{md.port} in #{duration}ms")
  end

  def handle_event([:mint, :http, :request, :start], _m, md, _) do
    Logger.debug("[Mint] Starting HTTP request to #{md.host}")
  end

  def handle_event([:mint, :http, :request, :stop], m, md, _) do
    duration = System.convert_time_unit(m.duration, :native, :millisecond)
    Logger.info("[Mint] Finished HTTP request to #{md.host} in #{duration}ms")
  end

  def handle_event([:mint, :http, :response, :stop], m, md, _) do
    duration = System.convert_time_unit(m.duration, :native, :millisecond)
    Logger.info("[Mint] Received full response from #{md.host} in #{duration}ms")
  end

  def handle_event([:mint, :http, :error], m, md, _) do
    Logger.error("[Mint] Error while requesting #{md.host}: #{inspect(m)}")
  end
end
