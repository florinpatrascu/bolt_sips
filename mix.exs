defmodule BoltSips.Mixfile do
  use Mix.Project

  @version "0.5.9"

  def project do
    [
      app: :bolt_sips,
      version: @version,
      elixir: "~> 1.5",
      deps: deps(),
      package: package(),
      description: "Neo4j driver for Elixir, using the fast Bolt protocol",
      name: "Bolt.Sips",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
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
    [
      applications:
        [
          :logger,
          :poolboy,
          :db_connection,
          :retry,
          :boltex,
          :fuzzyurl
        ] ++ opt_etls()
    ]
  end

  defp package do
    %{
      licenses: ["Apache 2.0"],
      maintainers: ["Florin T.PATRASCU", "Dmitriy Nesteryuk"],
      links: %{"Github" => "https://github.com/florinpatrascu/bolt_sips"}
    }
  end

  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:poolboy, "~> 1.5.1"},
      {:db_connection, github: 'elixir-ecto/db_connection', ref: "c65e26f"},
      # {:db_connection, "~> 1.1"},
      {:fuzzyurl, "~> 0.9.1"},
      {:retry, "~> 0.8.2"},
      {:ex_doc, "~> 0.18.3", only: [:dev]},
      {:mix_test_watch, "~> 0.6.0", only: [:dev, :test]},
      {:benchee, "~> 0.13", only: :dev},
      # {:boltex, path: "../boltex/"},
      {:boltex, "~> 0.4.1"},
      {:credo, "~> 0.9.3", only: [:dev, :test]}
    ] ++ env_specific_deps()
  end

  defp env_specific_deps do
    if System.get_env("BOLT_WITH_ETLS"), do: [{:etls, "~> 1.2"}], else: []
  end

  # when using Elixir < 1.4
  defp opt_etls do
    if System.get_env("BOLT_WITH_ETLS"), do: [:etls], else: []
  end
end
