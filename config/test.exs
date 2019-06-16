use Mix.Config

config :bolt_sips, Bolt,
  # default port considered to be: 7687
  url: "bolt://localhost",
  basic_auth: [username: "neo4j", password: "test"],
  pool_size: 10,
  max_overflow: 2,
  queue_interval: 500,
  queue_target: 1500,
  retry_linear_backoff: [delay: 150, factor: 2, tries: 2],
  prefix: :default

# the `retry_linear_backoff` values above are also the default driver values,
# re-defined here mostly as a reminder

level =
  if System.get_env("DEBUG") do
    :debug
  else
    :info
  end

config :bolt_sips,
  log: true,
  log_hex: false

config :logger, :console,
  level: level,
  format: "$date $time [$level] $metadata$message\n"

config :mix_test_watch,
  clear: true

config :tzdata, :autoupdate, :disabled
config :porcelain, driver: Porcelain.Driver.Basic
