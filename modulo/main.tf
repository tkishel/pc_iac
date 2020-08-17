provider "aws" {
  region = "us-west-2"
}

resource "aws_s3_bucket" "foo" {
  bucket        = "bar-pc-iac"
  region        = "us-west-2"
  acl           = "public-read-write"
  force_destroy = true
  versioning {
     enabled = false
  }
}

# For comparison:
#
# acl: "public-read-write" vs "private"
# versioning enabled: true vs false

# We don't have support for Azure or Google and Terraform 0.12 yet.
#
# You can scan a plan file directly with API;
# but the plugins cannot scan a plan file,
# or Azure or Google Terraform 0.12 templates.

#provider "google" {
#  region      = "us-west1"
#}
#
#resource "google_storage_bucket" "foo" {
#  name          = "bar-pc-iac"
#  location      = "us-west1"
#  force_destroy = true
#}

#provider "azurerm" {
#  features {}
#}

#resource "azurerm_resource_group" "foo" {
#  name     = "bar"
#  location = "West Central US"
#}

#resource "azurerm_storage_account" "foo" {
#  name                     = "bar"
#  resource_group_name      = azurerm_resource_group.foo.name
#  location                 = azurerm_resource_group.foo.location
#  account_tier             = "Standard"
#  account_replication_type = "LRS"
#  network_rules {
#    default_action = "Allow"
#  }
#}