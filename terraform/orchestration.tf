resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "afl-data-platform-orchestrator"
  role_arn = aws_iam_role.sfn.arn

  definition = <<EOF
{
  "Comment": "Orchestrates the AFL data platform",
  "StartAt": "Glue StartJobRun",
  "States": {
    "Glue StartJobRun": {
      "Type": "Task",
      "Resource": "arn:aws:states:::glue:startJobRun.sync",
      "Parameters": {
        "JobName": "${aws_glue_job.raw_ingestion.name}"
      },
      "Next": "StartCrawler"
    },
    "StartCrawler": {
      "Type": "Task",
      "Resource": "arn:aws:states:::aws-sdk:glue:startCrawler",
      "Parameters": {
        "Name": "${aws_glue_crawler.players.name}"
      },
      "End": true
    }
  }
}
EOF
}
