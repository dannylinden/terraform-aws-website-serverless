// Create a variable for our domain name
variable "www_domain" {
  description = "The domain of the Website, e.g www.example.org"
}

// We'll also need the root domain (also known as zone apex or naked domain).
variable "root_domain" {
  description = "Root Domain level, e.g. example.org"
}

variable "ssl-validation" {
  description = "How to validate the SSL Certificate? \"EMAIL\" or \"DNS\""
  default = "EMAIL"
}

variable "bucket_prefix" {
  description = "Prefix for S3 Buckets to handle already exist issues"
  default = ""
}

variable "ssh_pub_key" {
  type = "string"
  description = "Path to your Public SSH Key. Used to authenticate the Git Repository"
}

locals {
  domain_slug = "${replace(var.www_domain,".", "_")}"
}