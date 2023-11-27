#!/bin/bash

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
source ${SCRIPTPATH}/../versions.sh

docker image inspect digitalis-cassandra-util:$CASSANDRA_VERSION > /dev/null

status=$?

logit "digitalis-cassandra-util:$CASSANDRA_VERSION exists is $status"

if test $status -eq 1
then
	logit "Building docker image as does not exist"
	docker build -t digitalis-cassandra-util:$CASSANDRA_VERSION "${SCRIPTPATH}/../cassandra-util"
fi