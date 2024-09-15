resource "aws_s3_bucket" "glue_scripts" {
  bucket = "afl-data-platform-glue-scripts"
}

resource "aws_s3_object" "scraper" {
  bucket = aws_s3_bucket.glue_scripts.bucket
  key    = "scraper.py"
  source = "../scraper/main.py"
}

resource "aws_s3_bucket" "raw_data" {
  bucket = "afl-data-platform-raw-data"
}

resource "aws_s3_bucket" "athena" {
  bucket = "afl-data-platform-athena-queries"
}
