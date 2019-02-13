provider "azurerm" { 
    version = "~> 1.21"

    tenant_id       = "${var.azure_tenant_id}"
    subscription_id = "${var.azure_subscription_id}"
    client_id       = "${var.azure_client_id}"
    client_secret   = "${var.azure_client_secret}"
}

locals {
  iot_device_id = "TEST_DEVICE"
}   

resource "azurerm_resource_group" "main_rg" {
  name     = "${format("%s-rg", var.env)}"
  location = "${var.location}"

  tags {
    environment = "${var.env}"
  }
}

resource "random_string" "randomness" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_iothub" "iot" {
  name                    = "${format("iot-%s", random_string.randomness.result)}"
  resource_group_name     = "${azurerm_resource_group.main_rg.name}"
  location                = "${var.location}"

  sku {
    name     = "S1"
    tier     = "Standard"
    capacity = "1"
  }

  tags {
    environment = "${var.env}"
  }

  provisioner "local-exec" {
    command = "az iot hub device-identity create --device-id ${local.iot_device_id} --hub-name ${self.name} --resource-group ${azurerm_resource_group.main_rg.name}"
  }
}

resource "azurerm_storage_account" "listener" {
  name                     = "${format("listener%s", random_string.randomness.result)}"
  resource_group_name      = "${azurerm_resource_group.main_rg.name}"
  location                 = "${var.location}"
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  access_tier              = "Cool"
  account_replication_type = "LRS"

  tags {
    environment = "${var.env}"
  }
}

resource "null_resource" "env_vars_file" {
  // re-generate the file every deployment  
  triggers { 
      build_number = "${timestamp()}"
  }

  provisioner "local-exec" {
    working_dir = "${path.module}/../"
    command     = <<EOF
DEVICE_CONNECTION_STRING=$(az iot hub device-identity show-connection-string --device-id ${local.iot_device_id} --hub-name ${azurerm_iothub.iot.name} --resource-group ${azurerm_resource_group.main_rg.name} -o tsv)

cp -rf env.vars.tmpl env.vars

sed -i 's|#{storage_name}|'${azurerm_storage_account.listener.name}'|' ./env.vars
sed -i 's|#{storage_sak}|'${azurerm_storage_account.listener.primary_access_key}'|' ./env.vars
sed -i 's|#{iot_name}|'${azurerm_iothub.iot.name}'|' ./env.vars
sed -i 's|#{iot_service_sap}|'${lookup(azurerm_iothub.iot.shared_access_policy[1], "primary_key")}'|' ./env.vars
sed -i 's|#{iot_eh_name}|'${azurerm_iothub.iot.event_hub_events_path}'|' ./env.vars
sed -i 's|#{iot_eh_endpoint}|'${azurerm_iothub.iot.event_hub_events_endpoint }'|' ./env.vars
sed -i 's|#{iot_device_id}|'${local.iot_device_id}'|' ./env.vars
sed -i 's|#{iot_device_connection}|'$DEVICE_CONNECTION_STRING'|' ./env.vars

EOF
  }
}