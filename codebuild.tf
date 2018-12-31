resource "aws_codebuild_project" "codebuild" {
  name          = "${local.domain_slug}"
  description   = "Codebuild project for ${var.www_domain}"
  build_timeout = "5"
  service_role  = "${aws_iam_role.codepipeline_role.arn}"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/golang:1.11"
    type         = "LINUX_CONTAINER"
    environment_variable {
      "name"  = "S3_BUCKET"
      "value" = "${aws_s3_bucket.www.bucket}"
    }
  }

  source {
    type            = "CODECOMMIT"
    location        = "${aws_codecommit_repository.git_repository.clone_url_ssh}"
    git_clone_depth = 1
  }
}