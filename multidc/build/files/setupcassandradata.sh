#!/usr/bin/env bash
set -e

logit() {
    local logdate=$(date +"%Y%m%d-%H:%M:%S %Z")
    local message="[${logdate}] - ${*}"
    echo "${message}"
    logger "${message}"
}
eexit() {
    local error_str="$@"
    logit $error_str
    exit 1
}

logit "Setting system keyspaces to be multi DC"
cqlsh --cqlshrc=/cqlshrc -e "ALTER KEYSPACE system_auth WITH replication= {'class' : 'NetworkTopologyStrategy', 'alpha' : 3, 'omega' : 3};"
cqlsh --cqlshrc=/cqlshrc -e "ALTER KEYSPACE system_traces WITH replication= {'class' : 'NetworkTopologyStrategy', 'alpha' : 1, 'omega' : 1} AND durable_writes = false;"
cqlsh --cqlshrc=/cqlshrc -e "ALTER KEYSPACE system_distributed WITH replication= {'class' : 'NetworkTopologyStrategy', 'alpha' : 3, 'omega' : 3};"
cqlsh --cqlshrc=/cqlshrc -f /cql/test.cql

logit "Cassandra Data Setup"