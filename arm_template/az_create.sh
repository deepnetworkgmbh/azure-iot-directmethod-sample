#!/usr/bin/env bash

# $1 - environment name
# $2 - location

if [ "$#" -ne 2 ]; then
    echo "Incorrect number of parameters passed in."
    echo "Usage: $0 env_name location"
    exit 1
fi

RANDOM_STR="$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 6 | head -n 1)"
IOT_ENV=$1
LOCATION=$2

RG_NAME="$IOT_ENV-rg"
IOT_NAME="iot-$RANDOM_STR"
STORAGE_NAME="listener$RANDOM_STR"

DEVICE_ID="TEST_DEVICE"

az group create --location "$LOCATION" --name "$RG_NAME"

az group deployment create --resource-group "$RG_NAME" --mode Complete --template-file ./azuredeploy.json --parameters IotName="$IOT_NAME" StorageName="$STORAGE_NAME"

az iot hub device-identity create --device-id "$DEVICE_ID" --hub-name "$IOT_NAME" --resource-group "$RG_NAME"

# Generate env.vars file

DEVICE_CONNECTION_STRING=$(az iot hub device-identity show-connection-string --device-id "$DEVICE_ID" --hub-name "$IOT_NAME" --resource-group "$RG_NAME" -o tsv)
STORAGE_SAK=$(az storage account keys list -g "$RG_NAME" -n "$STORAGE_NAME" --query [0].value -o tsv)
IOT_SERVICE_SAP=$( az iot hub policy show --hub-name "$IOT_NAME" --resource-group "$RG_NAME" --name service --query primaryKey -o tsv)
IOT_EH_NAME=$(az iot hub show --name "$IOT_NAME" --resource-group "$RG_NAME" --query properties.eventHubEndpoints.events.path -o tsv)
IOT_EH_ENDPOINT=$(az iot hub show --name "$IOT_NAME" --resource-group "$RG_NAME" --query properties.eventHubEndpoints.events.endpoint -o tsv)

cp -rf ./../env.vars.tmpl ./../env.vars

sed -i 's|#{storage_name}|'"$STORAGE_NAME"'|' ./../env.vars
sed -i 's|#{storage_sak}|'"$STORAGE_SAK"'|' ./../env.vars
sed -i 's|#{iot_name}|'"$IOT_NAME"'|' ./../env.vars
sed -i 's|#{iot_service_sap}|'"$IOT_SERVICE_SAP"'|' ./../env.vars
sed -i 's|#{iot_eh_name}|'"$IOT_EH_NAME"'|' ./../env.vars
sed -i 's|#{iot_eh_endpoint}|'"$IOT_EH_ENDPOINT"'|' ./../env.vars
sed -i 's|#{iot_device_id}|'"$DEVICE_ID"'|' ./../env.vars
sed -i 's|#{iot_device_connection}|'"$DEVICE_CONNECTION_STRING"'|' ./../env.vars