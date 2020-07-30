provider "aws" {
  region = "us-west-2"
}

provider "google" {
  project     = "hello-world-277723"
  region      = "us-west1"
}

resource "aws_s3_bucket" "foo" {
  bucket        = "bar-pc-iac"
  region        = "us-west-2"
  acl           = "private"
  force_destroy = true
  versioning {
     enabled = false
  }  
}

# acl: "public-read-write" vs "private"
# versioning enabled: true vs false

resource "google_storage_bucket" "foo" {
  name          = "bar-pc-iac"
  location      = "us-west1"
  force_destroy = true
}
