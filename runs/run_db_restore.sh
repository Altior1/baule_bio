#!/bin/bash

if [ "$1" == "prod" ]; then
    if [ -e db_dump_scalingo_prod.sql ]; then
        ## Wiping step
        echo "WIPING LOCAL DATABASE"
        sleep 1
        echo "*"
        sleep 1
        echo "*"
        sleep 1
        echo "*"
        sleep 1
        echo "*"
        sleep 1
        echo "*"
        sleep 1
        psql "postgresql://${POSTGRES_USR}:${POSTGRES_PASSWD}@${POSTGRES_HOSTNAME}:5432/${POSTGRES_DBNAME}" <<EOF
        \i ./delete_sql.plsql
EOF
        if [ $? == 0 ]; then
                echo "WIPING SUCCEEDED"
                ## Restoring step
                echo "psql postgresql://${POSTGRES_USR}:${POSTGRES_PASSWD}@${POSTGRES_HOSTNAME}:5432/${POSTGRES_DBNAME} < db_dump_scalingo_prod.sql"
                psql "postgresql://${POSTGRES_USR}:${POSTGRES_PASSWD}@${POSTGRES_HOSTNAME}:5432/${POSTGRES_DBNAME}" < db_dump_scalingo_prod.sql
                if [ $? == 0 ]; then
                    echo "RESTORING SUCCEEDED"
                else
                    echo "!! RESTORING FAILED !!"
                fi
        else
                echo "WIPING FAILED"
                exit 1
        fi

    else
        echo "Vous n'avez pas effectué de sauvegarde de la PROD au préalable. "
        exit 1
    fi
else
    if [ -e db_dump_scalingo_dev.sql ]; then
        ## Wiping step
        echo "WIPING LOCAL DATABASE"
        sleep 1
        echo "*"
        sleep 1
        echo "*"
        sleep 1
        echo "*"
        sleep 1
        echo "*"
        sleep 1
        echo "*"
        sleep 1
        psql "postgresql://${POSTGRES_USR}:${POSTGRES_PASSWD}@${POSTGRES_HOSTNAME}:5432/${POSTGRES_DBNAME}" <<EOF
        \i ./delete_sql.plsql
EOF
        if [ $? == 0 ]; then
                echo "WIPING SUCCEEDED"
                ## Restoring step
                echo "psql postgresql://${POSTGRES_USR}:${POSTGRES_PASSWD}@${POSTGRES_HOSTNAME}:5432/${POSTGRES_DBNAME} < db_dump_scalingo_dev.sql"
                psql "postgresql://${POSTGRES_USR}:${POSTGRES_PASSWD}@${POSTGRES_HOSTNAME}:5432/${POSTGRES_DBNAME}" < db_dump_scalingo_dev.sql
                if [ $? == 0 ]; then
                    echo "RESTORING SUCCEEDED"
                else
                    echo "!! RESTORING FAILED !!"
                fi
        else
                echo "WIPING FAILED"
                exit 1
        fi
    else
        echo "Vous n'avez pas effectué de sauvegarde de la DEV au préalable. "
        exit 1
    fi
fi
