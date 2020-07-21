resource "aws_s3_bucket" "foo" {
  bucket        = "bar"
  acl           = "private"
  force_destroy = true
  versioning {
     enabled = false
  }  
}

#   acl           = "public-read-write"
#   acl           = "private"