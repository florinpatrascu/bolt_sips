use Mix.Config

config :bolt_sips, Bolt,
  # default port considered to be: 7687
  url: 'localhost',
  pool_size: 5,
  max_overflow: 1,
  # retry the request, in case of error - in the example below the retry will
  # linearly increase the delay from 150ms following a Fibonacci pattern,
  # cap the delay at 15 seconds (the value defined by the default `:timeout`
  # parameter) and giving up after 3 attempts
  retry_linear_backoff: [delay: 150, factor: 2, tries: 3]

# the `retry_linear_backoff` values above are also the default driver values,
# re-defined here mostly as a reminder

level =
  if System.get_env("DEBUG") do
    :debug
  else
    :info
  end

config :logger, :console,
  level: level,
  format: "$date $time [$level] $metadata$message\n"

config :mix_test_watch,
  clear: true
