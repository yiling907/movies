# 配置AWS提供商
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ===================== 基础网络配置 =====================
# VPC
resource "aws_vpc" "django_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "django-devops-vpc"
  }
}

# 公有子网（2个可用区，EB要求至少2个子网）
resource "aws_subnet" "django_subnet_1" {
  vpc_id            = aws_vpc.django_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = {
    Name = "django-devops-subnet-1a"
  }
}

resource "aws_subnet" "django_subnet_2" {
  vpc_id            = aws_vpc.django_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags = {
    Name = "django-devops-subnet-2b"
  }
}

# 互联网网关（EB需要公网访问）
resource "aws_internet_gateway" "django_igw" {
  vpc_id = aws_vpc.django_vpc.id
  tags = {
    Name = "django-devops-igw"
  }
}

# 路由表
resource "aws_route_table" "django_rt" {
  vpc_id = aws_vpc.django_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.django_igw.id
  }
  tags = {
    Name = "django-devops-rt"
  }
}

# 路由表关联子网
resource "aws_route_table_association" "django_rta_1" {
  subnet_id      = aws_subnet.django_subnet_1.id
  route_table_id = aws_route_table.django_rt.id
}

resource "aws_route_table_association" "django_rta_2" {
  subnet_id      = aws_subnet.django_subnet_2.id
  route_table_id = aws_route_table.django_rt.id
}

# RDS子网组（必须创建，用于绑定自定义VPC的子网）
resource "aws_db_subnet_group" "django_rds_subnet_group" {
  name       = "django-devops-rds-subnet-group"
  description = "Subnet group for Django RDS instance"
  subnet_ids = [aws_subnet.django_subnet_1.id, aws_subnet.django_subnet_2.id]

  tags = {
    Name = "django-devops-rds-subnet-group"
  }
}

# ===================== RDS配置 =====================
# RDS安全组（允许EB访问PostgreSQL）
resource "aws_security_group" "rds_sg" {
  name        = "django-rds-sg"
  description = "Allow PostgreSQL access from EB"
  vpc_id      = aws_vpc.django_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.eb_sg.id]  # 仅允许EB访问
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "django-rds-sg"
  }
}

# RDS PostgreSQL实例
resource "aws_db_instance" "django_rds" {
  identifier           = "django-devops-rds"
  engine               = "postgres"
  engine_version       = "17.6"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  storage_type         = "gp2"
  db_name              = var.rds_db_name
  username             = var.rds_username
  password             = var.rds_password
  port                 = 5432
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible  = false  # 生产级配置：仅内网访问
  skip_final_snapshot  = true
  deletion_protection  = false
  db_subnet_group_name = aws_db_subnet_group.django_rds_subnet_group.name

  tags = {
    Name = "django-devops-rds"
  }
}

# ===================== Elastic Beanstalk配置 =====================
# 1. EB应用存储桶（用于存放应用版本包）
resource "aws_s3_bucket" "eb_app_bucket" {
  bucket = "django-devops-eb-app-${random_string.suffix.result}"
  tags = {
    Name = "django-devops-eb-app-bucket"
  }

}

# 随机后缀（避免存储桶名称冲突）
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# 2. EB应用安全组
resource "aws_security_group" "eb_sg" {
  name        = "django-eb-sg"
  description = "Allow HTTP/HTTPS access to EB"
  vpc_id      = aws_vpc.django_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "django-eb-sg"
  }
}

# 3. EB应用
resource "aws_elastic_beanstalk_application" "django_eb_app" {
  name        = "django-devops-eb-app"
  description = "Django DevOps EB Application"

  # 版本生命周期配置
  appversion_lifecycle {
    service_role          = aws_iam_role.eb_service_role.arn
    max_count             = 128
    delete_source_from_s3 = true
  }
}

# 4. EB应用环境（运行环境）
resource "aws_elastic_beanstalk_environment" "django_eb_env" {
  name                = "django-devops-eb-env"
  application         = aws_elastic_beanstalk_application.django_eb_app.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.8.0 running Python 3.9"  # 适配Python版本

   depends_on = [
    aws_iam_instance_profile.eb_instance_profile,
    aws_iam_role_policy_attachment.eb_instance_role_policy
  ]
  # 环境配置
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance"  # 测试用，生产用LoadBalanced
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.eb_service_role.arn
  }

  setting {
    namespace = "aws:elasticbeanstalk:customoption"
    name      = "InstanceProfile"
    value     = aws_iam_instance_profile.eb_instance_profile.name
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"  # 关键：Launch Config中也需指定
    value     = aws_iam_instance_profile.eb_instance_profile.name
  }

  # 网络配置
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.django_vpc.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "${aws_subnet.django_subnet_1.id},${aws_subnet.django_subnet_2.id}"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.eb_sg.id
  }

  # Python配置
  setting {
    namespace = "aws:elasticbeanstalk:container:python"
    name      = "WSGIPath"
    value     = "movies/wsgi.py"
  }

  # 环境变量（连接RDS）
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_ENDPOINT"
    value     = aws_db_instance.django_rds.address
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_PORT"
    value     = aws_db_instance.django_rds.port
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_DB_NAME"
    value     = aws_db_instance.django_rds.db_name
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_USERNAME"
    value     = aws_db_instance.django_rds.username
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_PASSWORD"
    value     = var.rds_password
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SECRET_KEY"
    value     = var.django_secret_key
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DEBUG"
    value     = "False"  # 生产环境关闭DEBUG
  }

  tags = {
    Name = "django-devops-eb-env"
  }
}

# ===================== IAM角色（EB必需） =====================
# EB服务角色
resource "aws_iam_role" "eb_service_role" {
  name = "aws-elasticbeanstalk-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "elasticbeanstalk.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "elasticbeanstalk"
          }
        }
      }
    ]
  })
}

# 附加EB托管策略
resource "aws_iam_role_policy_attachment" "eb_service_role_policy" {
  role       = aws_iam_role.eb_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
}

# EB实例配置文件角色
resource "aws_iam_role" "eb_instance_role" {
  name = "aws-elasticbeanstalk-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# 附加EC2实例策略
resource "aws_iam_role_policy_attachment" "eb_instance_role_policy" {
  role       = aws_iam_role.eb_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_instance_profile" "eb_instance_profile" {
  name = "aws-elasticbeanstalk-ec2-instance-profile"
  role = aws_iam_role.eb_instance_role.name
}