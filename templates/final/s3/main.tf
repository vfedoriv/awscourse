resource "aws_s3_bucket" "vf_s3_bucket" {
  bucket = "vf-s3-bucket-1"
}

resource "aws_s3_bucket_public_access_block" "vf_bucket_access" {
  bucket = aws_s3_bucket.vf_s3_bucket.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
}
