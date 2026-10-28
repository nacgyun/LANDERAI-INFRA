resource "aws_cloudwatch_metric_alarm" "workflow_abnormal_termination" {
  alarm_name          = "${var.project_name}-${var.environment}-workflow-abnormal-termination"
  alarm_description   = "Prod landing page workflow failed or timed out at least once within one minute."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 1
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "abnormal"
    expression  = "FILL(failed,0)+FILL(timeout,0)"
    label       = "Failed or TimedOut"
    return_data = true
  }

  metric_query {
    id          = "failed"
    return_data = false

    metric {
      namespace   = "AWS/States"
      metric_name = "ExecutionsFailed"
      dimensions = {
        StateMachineArn = module.landing_page_workflow.state_machine_arn
      }
      period = 60
      stat   = "Sum"
    }
  }

  metric_query {
    id          = "timeout"
    return_data = false

    metric {
      namespace   = "AWS/States"
      metric_name = "ExecutionsTimedOut"
      dimensions = {
        StateMachineArn = module.landing_page_workflow.state_machine_arn
      }
      period = 60
      stat   = "Sum"
    }
  }

  alarm_actions = [aws_sns_topic.prod_alerts.arn]

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "api_5xx" {
  alarm_name          = "${var.project_name}-${var.environment}-api-5xx"
  alarm_description   = "Prod HTTP API returned at least one 5xx response within one minute."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 1
  treat_missing_data  = "notBreaching"

  namespace   = "AWS/ApiGateway"
  metric_name = "5xx"
  dimensions = {
    ApiId = module.api_gateway.api_id
  }
  period    = 60
  statistic = "Sum"

  alarm_actions = [aws_sns_topic.prod_alerts.arn]

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  alarm_name          = "${var.project_name}-${var.environment}-lambda-throttles"
  alarm_description   = "One or more prod Lambda functions were throttled within one minute."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 1
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "total_throttles"
    expression  = "FILL(api,0)+FILL(embedding,0)+FILL(design,0)+FILL(variant,0)+FILL(persist,0)+FILL(revision,0)"
    label       = "Total Lambda throttles"
    return_data = true
  }

  dynamic "metric_query" {
    for_each = {
      api       = module.api_lambda.function_name
      embedding = module.embedding_lambda.function_name
      design    = module.design_plan_lambda.function_name
      variant   = module.landing_page_variant_lambda.function_name
      persist   = module.persist_result_lambda.function_name
      revision  = module.revision_worker_lambda.function_name
    }

    content {
      id          = metric_query.key
      return_data = false

      metric {
        namespace   = "AWS/Lambda"
        metric_name = "Throttles"
        dimensions = {
          FunctionName = metric_query.value
        }
        period = 60
        stat   = "Sum"
      }
    }
  }

  alarm_actions = [aws_sns_topic.prod_alerts.arn]

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "revision_dlq_messages" {
  alarm_name          = "${var.project_name}-${var.environment}-revision-dlq-messages"
  alarm_description   = "One or more landing page revision messages reached the dead-letter queue."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 1
  treat_missing_data  = "notBreaching"

  namespace   = "AWS/SQS"
  metric_name = "ApproximateNumberOfMessagesVisible"
  dimensions = {
    QueueName = module.revision_queue.dlq_name
  }
  period    = 60
  statistic = "Maximum"

  alarm_actions = [aws_sns_topic.prod_alerts.arn]

  tags = var.tags
}

locals {
  dynamodb_alarm_table_names = {
    core    = module.dynamodb.table_names.core_table
    request = module.dynamodb.table_names.landing_request
    result  = module.dynamodb.table_names.landing_result
    rag     = module.dynamodb.table_names.rag_design_plan
  }
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_throttles" {
  alarm_name          = "${var.project_name}-${var.environment}-dynamodb-throttles"
  alarm_description   = "A read or write request was throttled on one or more prod DynamoDB tables."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 1
  treat_missing_data  = "notBreaching"

  metric_query {
    id = "total_throttles"
    expression = join("+", [
      for id in keys(local.dynamodb_alarm_table_names) :
      "FILL(${id}_read,0)+FILL(${id}_write,0)"
    ])
    label       = "Total DynamoDB throttles"
    return_data = true
  }

  dynamic "metric_query" {
    for_each = merge([
      for id, table_name in local.dynamodb_alarm_table_names : {
        "${id}_read" = {
          metric_name = "ReadThrottleEvents"
          table_name  = table_name
        }
        "${id}_write" = {
          metric_name = "WriteThrottleEvents"
          table_name  = table_name
        }
      }
    ]...)

    content {
      id          = metric_query.key
      return_data = false

      metric {
        namespace   = "AWS/DynamoDB"
        metric_name = metric_query.value.metric_name
        dimensions = {
          TableName = metric_query.value.table_name
        }
        period = 60
        stat   = "Sum"
      }
    }
  }

  alarm_actions = [aws_sns_topic.prod_alerts.arn]

  tags = var.tags
}
