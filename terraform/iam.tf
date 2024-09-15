/*
Glue roles
*/

resource "aws_iam_role" "glue" {
  name = "afl-data-platform-glue-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "glue.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "glue_cloudwatch_access" {
  name = "glue_cloudwatch_access_policy"
  role = aws_iam_role.glue.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = [
          "arn:aws:logs:ap-southeast-2:295668360022:log-group:/aws-glue/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "glue_catalog_access" {
  name = "glue_catalog_access_policy"
  role = aws_iam_role.glue.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "glue:GetDatabase",
          "glue:GetTable",
          "glue:CreateTable",
          "glue:UpdateTable",
          "glue:DeleteTable",
          "glue:BatchCreatePartition",
          "glue:BatchDeletePartition",
          "glue:GetPartition",
          "glue:BatchGetPartition",
          "glue:UpdatePartition"
        ],
        Resource = [
          "arn:aws:glue:ap-southeast-2:${data.aws_caller_identity.current.account_id}:catalog",
          "arn:aws:glue:ap-southeast-2:${data.aws_caller_identity.current.account_id}:database/${aws_glue_catalog_database.raw_data.name}",
          "arn:aws:glue:ap-southeast-2:${data.aws_caller_identity.current.account_id}:table/${aws_glue_catalog_database.raw_data.name}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "glue_s3_access" {
  name = "glue_s3_access_policy"
  role = aws_iam_role.glue.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.raw_data.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.raw_data.bucket}/*",
          "arn:aws:s3:::${aws_s3_bucket.glue_scripts.bucket}/*"
        ]
      }
    ]
  })
}

/*
Step Function roles
*/
resource "aws_iam_role" "sfn" {
  name = "afl-data-platform-sfn-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "states.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "sfn_glue_policy" {
  name = "sfn_glue_policy"
  role = aws_iam_role.sfn.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "glue:StartJobRun",
        "glue:GetJobRun",
        "glue:StartCrawler",
        "glue:GetCrawler"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
