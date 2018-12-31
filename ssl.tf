resource "aws_acm_certificate" "certificate" {
  domain_name = "${var.root_domain}"
  subject_alternative_names = ["www.${var.root_domain}"]
  validation_method = "${var.ssl-validation}"
  provider = "aws.us-east-1"
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = "${aws_acm_certificate.certificate.arn}"
  provider = "aws.us-east-1"
}
