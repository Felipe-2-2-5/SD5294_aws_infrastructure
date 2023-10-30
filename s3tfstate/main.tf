
resource "aws_s3_bucket" "tfstate" {
  bucket = "${var.project}-${var.environment}-tfstate"
}

resource "aws_s3_bucket_ownership_controls" "bucket_ower" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "tfstate_bucket_acl" {
  bucket = aws_s3_bucket.tfstate.id
  acl    = "private"
}
resource "aws_s3_bucket_versioning" "versioning_tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "dynamodb-lockid" {
  name           = "${var.project}_${var.environment}_tf_lockid"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "${var.project}_${var.environment}_tf_lockid"
    Environment = "${var.environment}"
    Project     = "${var.project}"
  }
}