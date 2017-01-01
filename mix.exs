defmodule BoltSips.Mixfile do
  use Mix.Project

  @version "0.1.6"

  def project do
    [
      app: :bolt_sips,
      version: @version,
      elixir: "~> 1.3",
      deps: deps(),
      package: package(),
      description: "Neo4j driver for Elixir wrapped around the fast Bolt protocol",
      name: "Bolt.Sips",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      docs: [
        extras: ["README.md", "CHANGELOG.md"],
        source_ref: "v#{@version}",
        source_url: "https://github.com/florinpatrascu/bolt_sips"
        ]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :poolboy, :con_cache, :etls],
     mod: {Bolt.Sips.Application, []}]
  end

  defp package do
    %{licenses: ["Apache 2.0"],
      maintainers: ["Florin T.PATRASCU"],
      links: %{"Github" => "https://github.com/florinpatrascu/bolt_sips"}}
  end

  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:poolboy, "~> 1.5"},
      {:con_cache, "~> 0.11"},
      {:etls, "~> 1.1"},
      {:fuzzyurl, "~> 0.9.0"},
      {:retry, "~> 0.6.0"},
      {:ex_doc, "~> 0.14", only: [:dev]},
      {:mix_test_watch, "~> 0.2", only: [:dev, :test]},
      {:credo, "~> 0.5", only: [:dev, :test]}
    ]
  end
end
