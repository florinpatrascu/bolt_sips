import Config

config :bolt_sips, Bolt,
  # default port considered to be: 7687
  url: "bolt://localhost",
  basic_auth: [username: "neo4j", password: "BoltSipsPassword"],
  pool_size: 10,
  max_overflow: 2,
  queue_interval: 500,
  queue_target: 1500,
  prefix: :default


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
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
config :porcelain, driver: Porcelain.Driver.Basic
