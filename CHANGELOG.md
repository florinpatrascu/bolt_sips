# Changelog

## v0.1.4 (Merry Christmas)
- add support for connecting to Neo4j servers on encrypted sockets. Currently only TLSv1.2 is supported, using the default [BoringSSL](https://boringssl.googlesource.com/boringssl/) cipher; via [:etls](https://github.com/kzemek/etls). To connect securely to a remote Neo4j server, such as the ones provided by graphenedb.com, modify your Bolt.Sips config file like this (example):

```elixir

config :bolt_sips, Bolt,
  hostname: 'bolt://hobby-blah.dbs.graphenedb.com',
  basic_auth: [username: "wow", password: "of_course_this_is_the_password"],
  port: 24786,
  pool_size: 5,
  secure: true,
  max_overflow: 1

```

Observe the new flag: `secure: true`

Please note this is work in progress

## v0.1.2 (2016-11-06)

- integrate the Boltex code from https://github.com/mschae/boltex, and let the Bolt.Sips wrapper to manage the connectivity, using a simple Poolboy implementation for connection pooling

## v0.1.1 (2016-09-09)

- a temporary solution for dealing with negative values while extracting a graph walk-through from a Path. Dealing with this in Boltex instead, but this fix should work for now.

## v0.1.0 (2016-08-31)

First release!
