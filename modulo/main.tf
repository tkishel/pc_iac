resource "aws_s3_bucket" "foo" {
  bucket        = "bar"
  acl           = "public-read-write"
  force_destroy = true
  versioning {
     enabled = false
  }  
}



#   acl           = "public-read-write"
#   acl           = "private"


