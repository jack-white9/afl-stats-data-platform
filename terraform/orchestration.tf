resource "aws_sfn_state_machine" "this" {
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

resource "aws_scheduler_schedule" "this" {
  name       = "afl-data-platform-orchestrator-schedule"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "cron(0 0 ? * 1 *)"
  schedule_expression_timezone = "Australia/Melbourne"

  target {
    arn      = aws_sfn_state_machine.this.arn
    role_arn = aws_iam_role.eventbridge.arn
  }
}
