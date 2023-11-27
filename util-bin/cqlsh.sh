#!/bin/bash
SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

source ${SCRIPTPATH}/lazybuild_digitalis-cassandra-util.sh

docker run --name cqlsh-$CASSANDRA_VERSION -it --rm -v "${SCRIPTPATH}/../docker/multidc/docker_containers/ssl:/root/.cassandra" --network="docker_digitalis-cassandra" -p 9000:9000 digitalis-cassandra-util:$CASSANDRA_VERSION cqlsh --cqlshrc=/root/.cassandra/cqlshrc
