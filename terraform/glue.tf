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

resource "aws_glue_catalog_database" "raw_data" {
  name = "afl-data-platform-raw-data"
}

# use one crawler per data source
resource "aws_glue_crawler" "players" {
  database_name = aws_glue_catalog_database.raw_data.name
  name          = "afl-data-platform-raw-data-crawler-players"
  role          = aws_iam_role.glue.arn

  s3_target {
    path = "s3://${aws_s3_bucket.raw_data.bucket}/players/"
  }
}
