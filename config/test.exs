use Mix.Config

config :bolt_sips, Bolt,
  url: 'localhost:7687',
  pool_size: 5,
  max_overflow: 1,
  timeout: 15_000,
  retry_linear_backoff: [delay: 150, factor: 2, tries: 3]

level = if System.get_env("DEBUG") do
  :debug
else
  :info
end

config :logger, :console,
  level: level,
  format: "$date $time [$level] $metadata$message\n"

config :mix_test_watch,
  clear: true
