# Help script

This script is used to run tests on different versions of databases and Bolt. You can customize the execution by specifying the test command, Bolt versions, and databases to use.

## Usage

The script uses docker-compose.yml file to configure database services and their associated Bolt versions. Each service should have labels that indicate the supported Bolt versions and the database it uses.

The labels that need to be set on each service are as follows:

- boltVersions: A comma-separated list of Bolt versions (e.g., "1.0,5.2").
- database: The name of the database that the service uses (e.g., "neo4j" or "memgraph"). Each service should have only one database.

The versions in boltVersions should be floating-point numbers, such as "1.0" instead of "1". These versions match the tags in Elixir tests, for example, @tag bolt_version: "1.0".

To run the script, you can use the following format:

```shell
./scripts/test-runner.sh -c "mix test" -b "1.0,5.2" -d "neo4j,memgraph"
```

or

```shell
./scripts/test-runner.sh -c "mix test --only last_version" -b "5.0, 5.2, 5.3" -d "neo4j"
```

This will execute tests with the specified command in different Bolt versions and databases according to the configuration in the docker-compose.yml file.

## Requirements
Make sure you have the following dependencies installed on your system before running the script:

- Docker-compose
- jq 1.6+

To run the script's tests, you'll also need:

- Bats 1.2.1+
- Bats Support
- Bats Assert

You can install the Bats dependencies as follows:

```shell
sudo apt-get install jq
sudo apt-get docker-compose
sudo apt-get install bats
```
