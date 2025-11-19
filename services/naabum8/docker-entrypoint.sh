#!/bin/sh
set -e

echo "🔧 Starting '${SERVICEM8_NAME}' internal service with runtime secret loading..."

if [ -f "/run/secrets/rabbitmq_username" ]; then
    export RABBITMQ_USERNAME=$(cat /run/secrets/rabbitmq_username)
    echo "✅ RabbitMQ username loaded"
else
    echo "❌ ERROR: RabbitMQ username secret not found"
    exit 1
fi

if [ -f "/run/secrets/rabbitmq_password" ]; then
    export RABBITMQ_PASSWORD=$(cat /run/secrets/rabbitmq_password)
    echo "✅ RabbitMQ password loaded"
else
    echo "❌ ERROR: RabbitMQ password secret not found"
    exit 1
fi

if [ -f "/run/secrets/postgresql_user_password" ]; then
    export POSTGRESQL_PASSWORD=$(cat /run/secrets/postgresql_user_password)
    echo "✅ Postgresql password loaded"
else
    echo "❌ ERROR: Postgresql password secret not found"
    exit 1
fi

# Load SMTP credentials
if [ -f "/run/secrets/smtp_username" ]; then
    export SMTP_USERNAME=$(cat /run/secrets/smtp_username)
    echo "✅ SMTP username loaded"
else
    echo "⚠️  WARNING: SMTP username secret not found"
fi

if [ -f "/run/secrets/smtp_password" ]; then
    export SMTP_PASSWORD=$(cat /run/secrets/smtp_password)
    echo "✅ SMTP password loaded"
else
    echo "⚠️  WARNING: SMTP password secret not found"
fi

# Load AWS credentials
if [ -f "/run/secrets/aws_key" ]; then
    export AWS_KEY=$(cat /run/secrets/aws_key)
    echo "✅ AWS key loaded"
else
    echo "⚠️  WARNING: AWS key secret not found"
fi

if [ -f "/run/secrets/aws_secret" ]; then
    export AWS_SECRET=$(cat /run/secrets/aws_secret)
    echo "✅ AWS secret loaded"
else
    echo "⚠️  WARNING: AWS secret not found"
fi

echo "✅ All secrets loaded ..."

# Process configuration.yaml to substitute environment variables
if [ -f "/app/configs/configuration_template.yaml" ]; then
    echo "🔧 Processing configuration.yaml with environment variables..."
    envsubst < /app/configs/configuration_template.yaml > /tmp/configuration_processed.yaml
    mv /tmp/configuration_processed.yaml /app/configs/configuration.yaml
    echo "✅ Configuration processed with environment variables"
fi

# Execute the main command passed as arguments
exec "$@"