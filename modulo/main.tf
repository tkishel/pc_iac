resource "aws_s3_bucket" "foo" {
  bucket        = "bar"
  acl           = "private"
  force_destroy = true
  versioning {
     enabled = false
  }  
}

# acl: "public-read-write" vs "private"
# versioning enabled: true vs false

#resource "google_storage_bucket" "foo" {
#  name = "bar.example.com"
#}
