# Changelog

## 0.4.11

- using Elixir 1.5
- not using the ConCache anymore. I initially intended to use its support throughout the driver, but it is not needed.
- README updated with a short snippet from a Phoenix web app demo, showing how to start Bolt.Sips, as a worker
- dependencies update
- minor code cleanup, to prep the code for receiving HA and Bolt routing capabilities

## v0.3.5

- better error messages; issue #33
- not retrying a connection when the server is not available/started
- incorrect number of retries, performed by the driver in case of errors; was one extra

## v0.3.4

- dependencies update, minor code cleanup, listening to Credo :) and finally using a Markdown linter

## v0.3.3

- Add link to travis build; #31 by vic

## v0.3.2

- Use the project's own configuration file when executing the `bolt.cypher` mix task. Fixes issue #20

## v0.3.1 Breaking changes

- rollback/refactor to optionally allow external configuration options to be defined at runtime. You must start the Bolt.Sips manually, when needed, i.e. `Bolt.Sips.start_link(url: "localhost")`, or by changing your app's mix config file, i.e.

```elixir
def application do
  [applications: [:logger, :bolt_sips],
   mod: {Bolt.Sips.Application, []}]
end
```

You can also specify custom configuration settings in you app's mix config file. These may overwrite your config file:

```elixir
def application do
  [extra_applications: [:logger], mod: 
    {Bolt.Sips.Application, [url: 'localhost', pool_size: 15]}
  ]
end
```

- code cleanup

## v0.2.6 (2017-04-21)

- cleanup, and minor dependencies update

## v0.2.5 (2017-03-22)

- split multi-line Cypher statements containing semicolons only if the `;` character is at the end of the line, followed by \r\n on Windows and \n on Unix like system, otherwise it may break the Cypher statement when the semicolon appears somewhere else

## v0.2.4 (2017-02-26)

- add the fuzzyurl to the list of apps, for project using Elixir < 1.4 (thank you, @dnesteryuk!)

## v0.2.3 (2017-02-26)

- improved connection handling

## v0.2.2 (2017-02-24)

- PR #18; Bring up `:boltex` and `:retry` in `applications`, for Elixir < 1.4 (from: @wli0503, thank you!)
- PR #19; test for error message on invalid parameter types (from: @vic, thank you!).

## v0.2.1 (2017-02-20)

- stop retrying a request if the failure is an internal one (driver, or driver dependencies related).
- update the Boltex driver containing two important bug fixes: one where Boltex will fail when receiving too much data (florinpatrascu/bolt_sips/issues/16) and the other one, an improvement, make Boltex.Error.get_id/1 more resilient for new transports (details here: mschae/boltex/issues/14)
- changed the pool strategy to :fifo, and its timeout to :infinity, and let the (:gen_server) call timeout expire according to the user's :timeout configuration parameter
- added a test unit provided by @adri (thank you), for executing a Cypher query, with large set of parameters

## v0.2.0 Breaking changes

- Elixir 1.4 is now required.
- Using Boltex 0.2.0
- bugfix: invalid Cypher statements will now be properly handled when the request is retried automatically 

## v0.1.11

- With a larger amount of parameters it seems like generating chunks isn't working correctly. This is a patch imported from Boltex, see: https://github.com/mschae/boltex/issues/13, for more info

## v0.1.10 (2017-02-11)

- accept Map and Struct for query parameters, transparently. Thank you [@wli0503], for the PR.

## v0.1.9 (2017-01-27)

Some of the users are encountering difficulties when trying to compile bolt_sips on Windows. This release is addressing their concern.

`Bolt.Sips` will use the optional System variable: `BOLT_WITH_ETLS`, for depending on the [ETLS](https://hex.pm/packages/etls) package. If that variable is not defined, then `Bolt.Sips` will use the standard Erlang [`:ssl` module](http://erlang.org/doc/man/ssl.html), for the SSL/TLS protocol; the default behavior, starting with this version.

Therefore, if you want the **much** faster ssl/tls support offered by ETLS, then use this: `export BOLT_WITH_ETLS=true` on Linux/OSX, for example. Then:

```elixir
 mix deps.get
 mix test
```

 and so on.

 (Don't forget to `mix deps.unlock --all`, if you plan to plan to further debugging/developing w/ or w/o the `BOLT_WITH_ETLS` support)

Many thanks to: [Ben Wilson](https://elixir-lang.slack.com/team/benwilson512), for advices.

## v0.1.8 (2017-01-07)

- using Elixir 1.4
- add more details to the README, about the components required to build ETLS, the TCP/TLS layer
- added newer Elixirs to the Travis CI configuration file
- minor code cleanups

## v0.1.7 (2017-01-02)

- Connection code refactored for capturing the errors when the remote server is not responding on the first request, or if the driver is misconfigured i.e. wrong port number, bad hostname ... 
- updated the test configuration file with detailed info about the newly introduced option: `:retry_linear_backoff`, mostly as a reminder

## v0.1.6 (2017-01-01)

- we're already using configurable timeouts, when executing requests from the connection pool. But with Bolt, the initial handshake sequence (happening before sending any commands to the server) is represented by two important calls, executed in sequence: `handshake` and `init`, and they must both succeed, before sending any (Cypher) requests. You can see the details in the [Bolt protocol](http://boltprotocol.org/v1/#handshake) specs. This sequence is also sensitive to latencies, such as: network latencies, busy servers, etc., and because of that we're introducing a simple support for retrying the handshake (and the subsequent requests) with a linear backoff, and try the handshake sequence (or the request) a couple of times before giving up - all these as part of the exiting pool management, of course. This retry is configurable via a new configuration parameter, the: `:retry_linear_backoff`, respectively. For example:

```elixir
config :bolt_sips, Bolt,
  url: "bolt://Bilbo:Baggins@hobby-hobbits.dbs.graphenedb.com:24786",
  ssl: true,
  timeout: 15_000,
  retry_linear_backoff: [delay: 150, factor: 2, tries: 3]
```

In the example above the retry will linearly increase the delay from 150ms following a Fibonacci pattern, cap the delay at 15 seconds (the value defined by the `:timeout` parameter) and giving up after 3 attempts. The same retry mechanism (and configuration parameters) is also honored when we send requests to the neo4j server.

## v0.1.5 (2016-12-30)

- as requested by many users, this version is introducing the optional `url` configuration parameter. If present, it will be used for extracting the host name, the port and the authentication details. Please see the README, for a couple of examples. For brevity:

```elixir

config :bolt_sips, Bolt,
  url: 'bolt://demo:demo@hobby-wowsoeasy.dbs.graphenedb.com:24786',
  ssl: true
```

## v0.1.4 (Merry Christmas)

- add support for connecting to Neo4j servers on encrypted sockets. Currently only TLSv1.2 is supported, using the default [BoringSSL](https://boringssl.googlesource.com/boringssl/) cipher; via [:etls](https://github.com/kzemek/etls). To connect securely to a remote Neo4j server, such as the ones provided by graphenedb.com, modify your Bolt.Sips config file like this (example):

```elixir

config :bolt_sips, Bolt,
  hostname: 'bolt://hobby-blah.dbs.graphenedb.com',
  basic_auth: [username: "wow", password: "of_course_this_is_the_password"],
  port: 24786,
  pool_size: 5,
  ssl: true,
  max_overflow: 1

```

Observe the new flag: `ssl: true`

Please note this is work in progress

## v0.1.2 (2016-11-06)

- integrate the Boltex code from https://github.com/mschae/boltex, and let the Bolt.Sips wrapper to manage the connectivity, using a simple Poolboy implementation for connection pooling

## v0.1.1 (2016-09-09)

- a temporary solution for dealing with negative values while extracting a graph walk-through from a Path. Dealing with this in Boltex instead, but this fix should work for now.

## v0.1.0 (2016-08-31)

First release!
