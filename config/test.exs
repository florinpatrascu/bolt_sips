use Mix.Config

config :bolt_sips, Bolt,
  url: 'localhost:7687',
  pool_size: 5,
  max_overflow: 1

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
