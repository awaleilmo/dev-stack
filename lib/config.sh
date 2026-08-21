# Dev Stack CLI Configuration
# Variables can be overridden via environment or .env file

: "${MISE_PHP_VERSION:=8.3}"
: "${MISE_NODE_VERSION:=22}"
: "${MISE_PYTHON_VERSION:=3.13}"

: "${DEV_STACK_HOME:-$HOME/dev-stack}"
: "${DEV_STACK_LIB_DIR:-$HOME/dev-stack/lib}"

# Service ports (defaults, can be overridden in .env)
: "${MYSQL_PORT:=3306}"
: "${POSTGRES_PORT:=5432}"
: "${REDIS_PORT:=6379}"
: "${MONGODB_PORT:=27017}"
: "${ADMINER_PORT:=8081}"
: "${MAILHOG_WEB_PORT:=8025}"
: "${MINIO_API_PORT:=9001}"
: "${PORTAINER_PORT:=9000}"
