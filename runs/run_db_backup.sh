#!/bin/bash


if [ "$1" == "prod" ]; then
        ### SAUVEGARDE DE LA PROD SCALINGO ###
        if [ -z "$SCALINGO_POSTGRESQL_URL_PROD" ]; then
                echo "SCALINGO_POSTGRESQL_URL_PROD est vide, vous devez la sourcer en premier lieu"
                exit 1
        fi
        if [ -z "$SCALINGO_POSTGRESQL_LOCAL_PROD" ]; then
                echo "SCALINGO_POSTGRESQL_LOCAL_PROD est vide, vous devez la sourcer en premier lieu. Elle est de la forme SCALINGO_POSTGRESQL_URL_PROD en remplaçant le hostname:port par 127.0.0.1:10001 (ne pas se tromper sur le PORT, différent de la DEV !!)"
                exit 1
        fi
        echo "*********************************"
        echo "ATTENTION INSTANCE DE PROD"
        echo "*********************************"

        sleep 1
        echo "*"
        sleep 1
        echo "*"
        sleep 1
        echo "*"

        echo "Mounting tunnel towards scalingo PROD"
        echo "scalingo --app intranet-ig-prod db-tunnel $SCALINGO_POSTGRESQL_URL"
        nohup scalingo --app intranet-ig-prod db-tunnel "${SCALINGO_POSTGRESQL_URL}" &
        DB_TUNNEL_PID=$!

        echo "Tunnel PID : $DB_TUNNEL_PID"
        sleep 2

        echo "pg_dump ${SCALINGO_POSTGRESQL_LOCAL_PROD} > db_dump_scalingo_prod.sql"
        pg_dump "${SCALINGO_POSTGRESQL_LOCAL_PROD}" > db_dump_scalingo_prod.sql
        if [ $? == 0 ]; then
                echo "Dump complete !"
        else
                echo "Dump failed ..."
        fi

        echo "Unmounting tunnel"
        kill $DB_TUNNEL_PID
else
        if [ "$1" == "local" ]; then
                ### SAUVEGARDE DE LA BASE LOCALE ###

                echo "*********************************"
                echo "INSTANCE LOCALE"
                echo "*********************************"

                sleep 1
                echo "*"
                sleep 1
                echo "*"
                sleep 1
                echo "*"

                PG_URL="postgresql://${POSTGRES_USR}:${POSTGRES_PASSWD}@${POSTGRES_HOSTNAME}:5432/${POSTGRES_DBNAME}"
                echo "pg_dump ${PG_URL} > db_dump_scalingo_local.sql"
                pg_dump "${PG_URL}" > db_dump_scalingo_local.sql
                if [ $? == 0 ]; then
                        echo "Dump complete !"
                else
                        echo "Dump failed ..."
                fi

        else
                ### SAUVEGARDE DE LA DEV SCALINGO ### 
                if [ -z "$SCALINGO_POSTGRESQL_URL_DEV" ]; then
                        echo "SCALINGO_POSTGRESQL_URL_DEV est vide, vous devez la sourcer en premier lieu"
                        exit 1
                fi
                if [ -z "$SCALINGO_POSTGRESQL_LOCAL_DEV" ]; then
                        echo "SCALINGO_POSTGRESQL_LOCAL_DEV est vide, vous devez la sourcer en premier lieu. Elle est de la forme SCALINGO_POSTGRESQL_URL_PROD en remplaçant le hostname:port par 127.0.0.1:10000 (ne pas se tromper sur le PORT, différent de la PROD !!)"
                        exit 1
                fi
                echo "*********************************"
                echo "INSTANCE DE DEV"
                echo "*********************************"

                sleep 1
                echo "*"
                sleep 1
                echo "*"
                sleep 1
                echo "*"

                echo "Mounting tunnel towards scalingo DEV"
                echo "scalingo --app intranet-ig-dev db-tunnel $SCALINGO_POSTGRESQL_URL_DEV"
                scalingo --app intranet-ig-dev db-tunnel "${SCALINGO_POSTGRESQL_URL_DEV}" &
                DB_TUNNEL_PID=$!

                echo "Tunnel PID : $DB_TUNNEL_PID"
                sleep 2

                echo "pg_dump ${SCALINGO_POSTGRESQL_LOCAL_DEV} > db_dump_scalingo_dev.sql"
                pg_dump "${SCALINGO_POSTGRESQL_LOCAL_DEV}" > db_dump_scalingo_dev.sql
                if [ $? == 0 ]; then
                        echo "Dump complete !"
                else
                        echo "Dump failed ..."
                fi

                echo "Unmounting tunnel"
                kill $DB_TUNNEL_PID
        fi
fi