#!/bin/bash

if [ -z "$1" ]; then
        echo "postgresql://${POSTGRES_USR}:****@${POSTGRES_HOSTNAME}:${POSTGRES_PORT}/${POSTGRES_DBNAME}"
        psql postgresql://${POSTGRES_USR}:${POSTGRES_PASSWD}@${POSTGRES_HOSTNAME}:${POSTGRES_PORT}/${POSTGRES_DBNAME}

else
        if [ "$1" == "prod" ]; then
                echo “*********************************”
                echo “ATTENTION INSTANCE DE PROD”
                echo “*********************************”
                echo "scalingo -a intranet-ig-prod pgsql-console"
                scalingo -a intranet-ig-prod pgsql-console
        else
                echo “INSTANCE DE DEV”
                echo "scalingo -a intranet-ig-dev pgsql-console"
                scalingo -a intranet-ig-dev pgsql-console
        fi
fi