#!/bin/sh

initdb \
    -D ${PGDATA} \
    --nodename=${PG_COORD_NODE}

echo "pg_hba: adding host trust"

echo "host	all	all  0.0.0.0/0    trust" >> \
    ${PGDATA}/pg_hba.conf
