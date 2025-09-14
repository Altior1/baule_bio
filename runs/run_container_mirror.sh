#!/bin/bash

if [ "$1" == "prod" ]; then
    echo “*********************************”
    echo “ATTENTION INSTANCE DE PROD”
    echo “*********************************”
    echo "scalingo --app intranet-ig-prod run bash"
    scalingo --app intranet-ig-prod run bash
else
    echo “INSTANCE DE DEV”
    echo "scalingo --app intranet-ig-dev run bash"
    scalingo --app intranet-ig-dev run bash
fi