defmodule BoltSips.Mixfile do
  use Mix.Project

  @version "0.3.4"

  def project do
    [
      app: :bolt_sips,
      version: @version,
      elixir: "~> 1.4",
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
    [applications: [:logger, :poolboy, :con_cache, :retry, :boltex, :fuzzyurl] ++ opt_etls(),
     #mod: {Bolt.Sips.Application, [foo: "bar"]}
    ]
  end

  defp package() do
    %{licenses: ["Apache 2.0"],
      maintainers: ["Florin T.PATRASCU"],
      links: %{"Github" => "https://github.com/florinpatrascu/bolt_sips"}}
  end

  # Type "mix help deps" for more examples and options
  defp deps() do
    [
      {:poolboy, "~> 1.5.1"},
      {:con_cache, "~> 0.12.0"},
      {:fuzzyurl, "~> 0.9.0"},
      {:retry, "~> 0.7"},
      {:ex_doc, "~> 0.16.2", only: [:dev]},
      {:mix_test_watch, "~> 0.4.1", only: [:dev, :test]},
      {:boltex, "~> 0.3"},
      {:benchee, "~> 0.9", only: :dev},
      # {:boltex, path: "../boltex/"},
      {:credo, "~> 0.8.6", only: [:dev, :test]}
    ] ++ env_specific_deps()
  end

  defp env_specific_deps do
    if System.get_env("BOLT_WITH_ETLS"), do: [{:etls, "~> 1.2"}], else: []
  end

  # when using Elixir < 1.4
  defp opt_etls() do
    if System.get_env("BOLT_WITH_ETLS"), do: [:etls], else: []
  end
end
