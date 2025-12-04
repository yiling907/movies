import os
from pathlib import Path
from dotenv import load_dotenv

# 加载环境变量（优先EB环境变量，其次本地.env）
load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: 生产环境由EB环境变量注入
SECRET_KEY = os.getenv('SECRET_KEY', 'django-insecure-uu=ioelb#y3*sr0m@2g(*l@+^j(wm-*%koz2f)e822*9b&i+@h')

# EB环境自动设置为False
DEBUG = os.getenv('DEBUG', 'False') == 'True'

# EB自动分配的域名
ALLOWED_HOSTS = [
    os.getenv('EB_ENVIRONMENT_URL', 'localhost'),
    'localhost',
    '127.0.0.1'
]

# 静态文件配置（适配EB）
STATIC_ROOT = os.path.join(BASE_DIR, 'static')
STATIC_URL = '/static/'

# 数据库配置（EB环境变量注入）
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('RDS_DB_NAME'),
        'USER': os.getenv('RDS_USERNAME'),
        'PASSWORD': os.getenv('RDS_PASSWORD'),
        'HOST': os.getenv('RDS_ENDPOINT'),
        'PORT': os.getenv('RDS_PORT', '5432'),
        'CONN_MAX_AGE': 600,  # 连接池优化
    }
}

# 安全中间件（生产环境）
if not DEBUG:
    SECURE_SSL_REDIRECT = True
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_HSTS_SECONDS = 31536000  # 1年
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True