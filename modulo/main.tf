provider "aws" {
  region = "${var.aws-region}"
}

resource "aws_s3_bucket" "foo" {
  bucket        = "bar-pc-iac"
  region        = "${var.aws-region}"
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

provider "google" {
  region = "${var.gcp-region}"
}

resource "google_storage_bucket" "foo" {
  name          = "bar-pc-iac"
  location      = "${var.gcp-region}"
  force_destroy = true
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "foo" {
  name     = "azrg"
  location = "${var.az-region}"
}

resource "azurerm_storage_account" "foo" {
  name                     = "azsa"
  resource_group_name      = "azrg"
  location                 = "${var.az-region}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}