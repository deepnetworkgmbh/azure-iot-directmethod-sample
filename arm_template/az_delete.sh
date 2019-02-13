#!/usr/bin/env bash

# $1 - environment name


if [ "$#" -ne 1 ]; then
    echo "Incorrect number of parameters passed in."
    echo "Usage: $0 env_name "
    exit 1
fi

RG_NAME="$1-rg"

az group delete --name "$RG_NAME" --yes