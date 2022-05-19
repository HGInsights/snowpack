defmodule Snowpack.MixProject do
  use Mix.Project

  @name "Snowpack"
  @source_url "https://github.com/HGInsights/snowpack"

  def project do
    [
      app: :snowpack,
      version: app_version(),
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      name: @name,
      description: "Snowflake driver for Elixir",
      source_url: @source_url,
      test_coverage: [tool: ExCoveralls],
      package: package(),
      docs: docs(),
      deps: deps(),
      preferred_cli_env: preferred_cli_env(),
      bless_suite: bless_suite(),
      dialyzer: dialyzer(),
      aliases: aliases()
    ]
  end

  # Configuration for the OTP application
  def application do
    [
      extra_applications: [:logger, :odbc],
      mod: {Snowpack.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package() do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      source_ref: "v#{app_version()}",
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
      {:jason, "~> 1.2"},
      {:bless, "~> 1.2", only: [:dev, :test]},
      {:excoveralls, "~> 0.14.4", only: [:dev, :test]},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test, :docs], runtime: false},
      {:ex_doc, ">= 0.0.0", only: [:docs], runtime: false},
      {:mix_test_watch, "~> 1.1.0", only: [:test, :dev]},
      {:mimic, "~> 1.7", only: [:dev, :test]},
      {:vapor, "~> 0.10.0", only: [:dev, :test, :docs], runtime: false}
    ]
  end

  defp preferred_cli_env,
    do: [bless: :test, coveralls: :test, "coveralls.html": :test, credo: :test, docs: :docs, dialyzer: :test, qc: :test]

  defp bless_suite do
    [
      compile: ["--warnings-as-errors", "--force"],
      format: ["--check-formatted"],
      credo: ["--strict"],
      "deps.unlock": ["--check-unused"],
      coveralls: ["--exclude", "skip_ci"]
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:ex_unit, :mix],
      ignore_warnings: "dialyzer.ignore-warnings",
      list_unused_filters: true
    ]
  end

  defp aliases do
    [
      qc: ["format", "credo --strict", "test"]
    ]
  end

  defp app_version do
    System.get_env("APP_VERSION", "v0.0.0")
    |> String.trim_leading("v")
  end
end
