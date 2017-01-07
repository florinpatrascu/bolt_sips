# Changelog

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
