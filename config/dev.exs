import Config

config :mix_test_watch,
  clear: true

level =
  if System.get_env("DEBUG") do
    :debug
  else
    :info
  end

config :bolt_sips,
  log: false,
  log_hex: false

config :logger, :console,
  level: level,
  format: "$date $time [$level] $metadata$message\n"

config :tzdata, :autoupdate, :disabled
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
