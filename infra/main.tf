# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.96.0"
    }
  }
  cloud {
    organization = "feketesamu"
    workspaces {
      name = "tf-poc"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "tf-rg" {
  name     = "terraform-poc"
  location = "West Europe"
}

resource "azurerm_api_management" "apim" {
  name                = "wikimedia-tf"
  location            = azurerm_resource_group.tf-rg.location
  resource_group_name = azurerm_resource_group.tf-rg.name
  publisher_name      = "Fekete Sámuel"
  publisher_email     = "feketesamu@gmail.com"

  sku_name = "Consumption_0"
}

resource "azurerm_api_management_api" "wm-api" {
  name                  = "onthisday-api"
  resource_group_name   = azurerm_resource_group.tf-rg.name
  api_management_name   = azurerm_api_management.apim.name
  revision              = "2"
  display_name          = "On this day API"
  protocols             = ["https"]
  service_url           = "https://api.wikimedia.org/feed/v1/wikipedia/en/onthisday/"
  subscription_required = false
}

resource "azurerm_api_management_api_operation" "get-onthisday" {
  operation_id        = "get-onthisday"
  api_name            = azurerm_api_management_api.wm-api.name
  api_management_name = azurerm_api_management_api.wm-api.api_management_name
  resource_group_name = azurerm_api_management_api.wm-api.resource_group_name
  display_name        = "Get event on this day"
  method              = "GET"
  url_template        = "/selected/{month}/{day}"

  template_parameter {
    name     = "month"
    type     = "string"
    required = true
  }

  template_parameter {
    name     = "day"
    type     = "string"
    required = true
  }

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation_policy" "onthisday-policy" {
  api_name            = azurerm_api_management_api_operation.get-onthisday.api_name
  api_management_name = azurerm_api_management_api_operation.get-onthisday.api_management_name
  resource_group_name = azurerm_api_management_api_operation.get-onthisday.resource_group_name
  operation_id        = azurerm_api_management_api_operation.get-onthisday.operation_id

  xml_content = <<XML
<policies>
        <inbound>
            <base />
        </inbound>
        <backend>
            <base />
        </backend>
        <outbound>
            <base />
            <choose>
                <when condition="@(context.Response.StatusCode == 200)">
                    <set-body>@{
                            var responseBody = context.Response.Body.As<JObject>();
                            var selectedArray = responseBody["selected"] as JArray;
                            var first = selectedArray.First() as JObject;
                            var newResponse = new JObject(new JProperty("event", first["text"]));
                            return newResponse.ToString();
                        }</set-body>
                </when>
            </choose>
        </outbound>
        <on-error>
            <base />
        </on-error>
      </policies>
XML
}

resource "azurerm_static_web_app" "spa" {
  name                = "tf-spa"
  location            = azurerm_resource_group.tf-rg.location
  resource_group_name = azurerm_resource_group.tf-rg.name
}

output "swa_api_key" {
  value     = azurerm_static_web_app.spa.api_key
  sensitive = true
}
