terraform {
  required_version = ">= 0.13.0"
}

provider "aws" {
  region = var.aws_region
}

provider "azurerm" {
  features {}
}

provider "google" {
  region = var.google_region
}






resource "aws_s3_bucket" "foo" {
  bucket        = "bar-pc-iac"
  acl           = "public-read-write"
  force_destroy = true
  versioning {
     enabled = false
  }
}

resource "azurerm_resource_group" "foo" {
 name     = "azrg"
 location = var.azure_region
}

resource "azurerm_storage_account" "foo" {
  name                     = "azsa"
  resource_group_name      = "azrg"
  location                 = var.azure_region
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "google_storage_bucket" "foo" {
  name          = "bar-pc-iac"
  location      = var.google_region
  force_destroy = true
}








# For comparison:
# acl: "public-read-write" vs "private"
# versioning enabled: true vs false

####
# Disable Global Protect
# To Avoid:
# Error: Error building account: Error getting authenticated object ID: Error parsing json result from the Azure CLI: Error waiting for the Azure CLI: exit status 1
####
