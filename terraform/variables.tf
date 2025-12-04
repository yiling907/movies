variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# RDS变量
variable "rds_db_name" {
  description = "RDS database name"
  type        = string
}

variable "rds_username" {
  description = "RDS username"
  type        = string
}

variable "rds_password" {
  description = "RDS password"
  type        = string
  sensitive   = true
}

# Django变量
variable "django_secret_key" {
  description = "Django secret key"
  type        = string
  sensitive   = true
}

# EB变量
variable "eb_solution_stack" {
  description = "EB solution stack name"
  type        = string
  default     = "64bit Amazon Linux 2023 v4.0.1 running Python 3.9"
}