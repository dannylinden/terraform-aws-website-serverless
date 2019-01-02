resource "aws_s3_bucket" "codepipeline" {
  bucket = "${var.bucket_prefix}codepipeline-${var.www_domain}"
  acl    = "private"
}

resource "aws_s3_bucket" "www" {
  bucket = "${var.bucket_prefix}${var.www_domain}"

  acl    = "public-read"

  policy = <<POLICY
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Sid":"AddPerm",
      "Effect":"Allow",
      "Principal": "*",
      "Action":["s3:GetObject"],
      "Resource":["arn:aws:s3:::${var.bucket_prefix}${var.www_domain}/*"]
    }
  ]
}
POLICY

  // S3 understands what it means to host a website.
  website {
    index_document = "index.html"
    error_document = "404.html"
  }
}

resource "aws_s3_bucket" "non-www" {
  bucket = "${var.bucket_prefix}${var.root_domain}"
  acl    = "public-read"
  policy = <<POLICY
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Sid":"AddPerm",
      "Effect":"Allow",
      "Principal": "*",
      "Action":["s3:GetObject"],
      "Resource":["arn:aws:s3:::${var.bucket_prefix}${var.root_domain}/*"]
    }
  ]
}
POLICY

  website {
    redirect_all_requests_to = "https://${var.www_domain}"
  }
}