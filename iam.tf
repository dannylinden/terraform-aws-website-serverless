resource "aws_iam_group" "committers_group" {
  name = "committers-${var.www_domain}"
}

resource "aws_iam_group_policy" "committer_direct_policies" {
  name = "committer_group_policy-${var.www_domain}"
  group = "${aws_iam_group.committers_group.id}"
  policy = "${data.aws_iam_policy_document.committer.json}"
}

resource "aws_iam_group_policy_attachment" "committer_managed_policy" {
  group      = "${aws_iam_group.committers_group.name}"
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitFullAccess"
}

data "aws_iam_policy_document" "committer" {
  statement {
    effect = "Allow"
    resources = ["*"]
    actions = [
      "iam:IAMSelfManageServiceSpecificCredentials",
      "iam:IAMReadOnlyAccess"
    ]
  }
}

resource "aws_iam_user" "code-commit" {
  name = "${var.www_domain}-commiter"
  path = "/"
}

resource "aws_iam_user_ssh_key" "user" {
  username   = "${aws_iam_user.code-commit.name}"
  encoding   = "SSH"
  public_key = "${file("${var.ssh_pub_key}")}"
}

resource "aws_iam_group_membership" "commiter-group" {
  name = "tf-${var.www_domain}-group-membership"

  users = [
    "${aws_iam_user.code-commit.name}"
  ]

  group = "${aws_iam_group.committers_group.name}"
}

resource "aws_iam_policy" "pipeline_checkout_policy" {
  name        = "${var.www_domain}_CodeRepository_PipelineCheckout"
  path        = "/${var.www_domain}/"
  description = "Policy to allow pipelines to pull from ${aws_codecommit_repository.git_repository.repository_name}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "codecommit:BatchGet*",
        "codecommit:Get*",
        "codecommit:List*",
        "codecommit:Create*",
        "codecommit:DeleteBranch",
        "codecommit:Describe*",
        "codecommit:Put*",
        "codecommit:Post*",
        "codecommit:Merge*",
        "codecommit:Test*",
        "codecommit:Update*",
        "codecommit:UploadArchive",
        "codecommit:GetUploadArchiveStatus",
        "codecommit:CancelUploadArchive",
        "codecommit:GitPull",
        "codecommit:GitPush"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudWatchEventsCodeCommitRulesReadOnlyAccess",
      "Effect": "Allow",
      "Action": [
        "events:DeleteRule",
        "events:DescribeRule",
        "events:DisableRule",
        "events:EnableRule",
        "events:PutRule",
        "events:PutTargets",
        "events:RemoveTargets",
        "events:ListTargetsByRule"
      ],
      "Resource": "arn:aws:events:*:*:rule/codecommit*"
    },
    {
      "Sid": "SNSTopicAndSubscriptionAccess",
      "Effect": "Allow",
      "Action": [
        "sns:Subscribe",
        "sns:Unsubscribe"
      ],
      "Resource": "arn:aws:sns:*:*:codecommit*"
    },
    {
      "Sid": "SNSTopicAndSubscriptionReadAccess",
      "Effect": "Allow",
      "Action": [
        "sns:ListTopics",
        "sns:ListSubscriptionsByTopic",
        "sns:GetTopicAttributes"
      ],
      "Resource": "*"
    },
    {
      "Sid": "LambdaReadOnlyListAccess",
      "Effect": "Allow",
      "Action": [
        "iam:ListUsers"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMReadOnlyConsoleAccess",
      "Effect": "Allow",
      "Action": [
        "iam:ListAccessKeys",
        "iam:ListSSHPublicKeys",
        "iam:ListServiceSpecificCredentials",
        "iam:ListAccessKeys",
        "iam:GetSSHPublicKey"
      ],
      "Resource": "arn:aws:iam::*:user/$${aws:username}"
    },
    {
      "Sid": "IAMUserSSHKeys",
      "Effect": "Allow",
      "Action": [
        "iam:DeleteSSHPublicKey",
        "iam:GetSSHPublicKey",
        "iam:ListSSHPublicKeys",
        "iam:UpdateSSHPublicKey",
        "iam:UploadSSHPublicKey"
      ],
      "Resource": "arn:aws:iam::*:user/$${aws:username}"
    },
    {
      "Sid": "IAMSelfManageServiceSpecificCredentials",
      "Effect": "Allow",
      "Action": [
        "iam:CreateServiceSpecificCredential",
        "iam:UpdateServiceSpecificCredential",
        "iam:DeleteServiceSpecificCredential",
        "iam:ResetServiceSpecificCredential"
      ],
      "Resource": "arn:aws:iam::*:user/$${aws:username}"
    }
  ]
}
POLICY
}

resource "aws_iam_role" "codepipeline_role" {

  name = "codepipeline-${var.www_domain}-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline-${var.www_domain}-policy"
  role = "${aws_iam_role.codepipeline_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
     {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${aws_s3_bucket.www.arn}",
        "${aws_s3_bucket.www.arn}/*",
        "${aws_s3_bucket.codepipeline.arn}",
        "${aws_s3_bucket.codepipeline.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
        "Effect": "Allow",
        "Resource": [
            "*"
        ],
        "Action": [
            "codecommit:GitPull"
        ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Resource": [
            "${aws_codecommit_repository.git_repository.arn}"
        ],
        "Action": [
            "codecommit:*"
        ]
    }
  ]
}
EOF
}