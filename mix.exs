defmodule Skitter.MixProject do
  use Mix.Project

  def project do
    [
      app: :skitter,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Skitter.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:httpoison, "~> 1.8"},
      {:floki, "~> 0.34.0"},
      {:jason, "~> 1.4"},
      {:nimble_publisher, "~> 1.0"},
      {:telemetry, "~> 1.2"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:finch, "~> 0.20.0"},
      {:mint, "~> 1.7.0"},
      {:ex_doc, "~> 0.30", only: :dev, runtime: false},
      {:qtrace, "~> 1.0", only: [:dev, :test]},
    ]
  end
end
