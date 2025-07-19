defmodule Skitter.Application do
  use Application

  def start(_type, _args) do
    Skitter.Cache.init()
    children = [
      Skitter.LinkStore,
      {DynamicSupervisor, strategy: :one_for_one, name: Skitter.CrawlerSupervisor},
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Skitter.Supervisor)
  end
end
