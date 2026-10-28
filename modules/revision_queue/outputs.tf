output "queue_arn" {
  value       = aws_sqs_queue.this.arn
  description = "Revision queue ARN."
}

output "queue_url" {
  value       = aws_sqs_queue.this.id
  description = "Revision queue URL."
}

output "queue_name" {
  value       = aws_sqs_queue.this.name
  description = "Revision queue name."
}

output "dlq_arn" {
  value       = aws_sqs_queue.dlq.arn
  description = "Revision dead-letter queue ARN."
}

output "dlq_url" {
  value       = aws_sqs_queue.dlq.id
  description = "Revision dead-letter queue URL."
}

output "dlq_name" {
  value       = aws_sqs_queue.dlq.name
  description = "Revision dead-letter queue name."
}
