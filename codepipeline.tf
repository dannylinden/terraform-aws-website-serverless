resource "aws_codepipeline" "codepipeline" {
  name = "codepipeline-${var.www_domain}"

  role_arn = "${aws_iam_role.codepipeline_role.arn}"

  artifact_store = {
    location = "${aws_s3_bucket.codepipeline.bucket}"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source"]

      configuration {
        RepositoryName = "${var.www_domain}"
        BranchName     = "${aws_codecommit_repository.git_repository.default_branch}"
      }
    }
  }

  stage {
    name = "Package"

    action {
      name             = "Package"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source"]
      output_artifacts = ["packaged"]
      version          = "1"

      configuration {
        ProjectName = "${aws_codebuild_project.codebuild.name}"
      }
    }
  }
}