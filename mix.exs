defmodule Snowpack.MixProject do
  use Mix.Project

  @name "Snowpack"
  @version "0.1.0"
  @source_url "https://github.com/HGInsights/snowpack"

  def project do
    [
      app: :snowpack,
      version: @version,
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      name: @name,
      description: "Snowflake driver for Elixir",
      source_url: @source_url,
      package: package(),
      docs: docs(),
      deps: deps(),
      preferred_cli_env: preferred_cli_env(),
      dialyzer: dialyzer(),
      aliases: aliases()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger, :odbc]
    ]
  end

  defp package() do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      source_url: @source_url,
      main: @name,
      extras: ["CHANGELOG.md"],
      groups_for_extras: [
        CHANGELOG: "CHANGELOG.md"
      ]
    ]
  end

  defp deps do
    [
      {:db_connection, "~> 2.2"},
      {:decimal, "~> 1.6 or ~> 2.0"},
      {:backoff, "~> 1.1"},
      {:date_time_parser, "~> 1.1.1"},
      {:mentat, "~> 0.7.1"},
      {:telemetry, "~> 0.4 or ~> 1.0"},
      {:vapor, "~> 0.10.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp preferred_cli_env, do: [qc: :test, credo: :test, dialyzer: :test]

  defp dialyzer do
    [
      plt_add_apps: [:ex_unit, :mix],
      ignore_warnings: "dialyzer.ignore-warnings"
    ]
  end

  defp aliases do
    [
      qc: ["format", "credo --strict", "test"]
    ]
  end
end
