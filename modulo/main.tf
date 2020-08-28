terraform {
  required_version = ">= 0.12.0"
}

provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_s3_bucket" "foo" {
  bucket        = "bar-pc-iac"
  region        = "${var.aws_region}"
  acl           = "public-read-write"
  force_destroy = true
  versioning {
     enabled = false
  }
}

# For comparison:
# acl: "public-read-write" vs "private"
# versioning enabled: true vs false

####

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "foo" {
 name     = "azrg"
 location = "${var.azure_region}"
}

resource "azurerm_storage_account" "foo" {
  name                     = "azsa"
  resource_group_name      = "azrg"
  location                 = "${var.azure_region}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

####

provider "google" {
  region = "us-west1"
}

resource "google_storage_bucket" "foo" {
  name          = "bar-pc-iac"
  location      = "${var.google_region}"
  force_destroy = true
}

# changes