# Create s3 bucket to store glue script
resource "aws_s3_bucket" "glue_scripts" {
  bucket = "afl-data-platform-glue-scripts"
}

resource "aws_s3_object" "scraper" {
  bucket = aws_s3_bucket.glue_scripts.bucket
  key    = "scraper.py"
  source = "../scraper/main.py"
}

# Create s3 bucket for raw data ingested by glue job
resource "aws_s3_bucket" "raw_data" {
  bucket = "afl-data-platform-raw-data"
}

# Create glue role
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


# Create glue job
resource "aws_glue_job" "raw_ingestion" {
  name     = "afl-data-platform-raw-ingestion"
  role_arn = aws_iam_role.glue.arn

  command {
    script_location = "s3://${aws_s3_bucket.glue_scripts.bucket}/${aws_s3_object.scraper.key}"
    python_version  = "3"
  }

  default_arguments = {
    "--additional-python-modules" = "beautifulsoup4==4.12.3"
  }
}
