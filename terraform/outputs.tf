# RDS输出
output "rds_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.django_rds.address
}

output "rds_port" {
  description = "RDS port"
  value       = aws_db_instance.django_rds.port
}

output "rds_db_name" {
  description = "RDS database name"
  value       = aws_db_instance.django_rds.db_name
}

# EB输出
output "eb_environment_name" {
  description = "EB environment name"
  value       = aws_elastic_beanstalk_environment.django_eb_env.name
}

output "eb_environment_url" {
  description = "EB environment URL"
  value       = aws_elastic_beanstalk_environment.django_eb_env.cname
}

output "eb_application_name" {
  description = "EB application name"
  value       = aws_elastic_beanstalk_application.django_eb_app.name
}

output "eb_s3_bucket_name" {
  description = "EB application S3 bucket name"
  value       = aws_s3_bucket.eb_app_bucket.bucket
}
