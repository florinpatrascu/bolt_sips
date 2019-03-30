defmodule BoltSips.Mixfile do
  use Mix.Project

  @version "1.5.1"

  def project do
    [
      app: :bolt_sips,
      version: @version,
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      package: package(),
      description: "Neo4j driver for Elixir, using the fast Bolt protocol",
      name: "Bolt.Sips",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      docs: [
        main: "readme",
        extras: ["README.md", "CHANGELOG.md"],
        source_ref: "v#{@version}",
        source_url: "https://github.com/florinpatrascu/bolt_sips"
      ],
      dialyzer: [plt_add_apps: [:jason, :poison, :mix], ignore_warnings: ".dialyzer_ignore.exs"],
      aliases: aliases()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      applications: [
        :logger,
        :calendar,
        :db_connection,
        :retry,
        :fuzzyurl
      ]
    ]
  end

  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      test: [
        "test --exclude bolt_v1 --exclude enterprise_only"
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    %{
      licenses: ["Apache 2.0"],
      maintainers: ["Florin T.PATRASCU", "Dmitriy Nesteryuk", "Dominique VASSARD"],
      links: %{"Github" => "https://github.com/florinpatrascu/bolt_sips"}
    }
  end

  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:db_connection, "~> 2.0"},
      {:fuzzyurl, "~> 1.0"},
      {:retry, "0.9.1"},
      {:calendar, "~> 0.17.2"},
      {:jason, "~> 1.1"},
      {:poison, "~> 3.1"},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:mix_test_watch, "~> 0.9", only: [:dev, :test]},
      {:benchee, "~> 0.14", only: :dev},
      {:credo, "~> 1.0", only: [:dev, :test]},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev], runtime: false}
    ]
  end
end
