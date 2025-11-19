#!/bin/sh
set -e

# Configuration
RABBITMQ_HOST="${RABBITMQ_HOSTNAME:-rabbitmqm8-cptm8-net}"
RABBITMQ_PORT="${RABBITMQ_PORT:-5672}"
RABBITMQ_MGMT_PORT="${RABBITMQ_MGMT_PORT:-15672}"
MAX_ATTEMPTS=30
WAIT_INTERVAL=5

echo "🔍 Waiting for RabbitMQ to be ready..."
echo "   Host: ${RABBITMQ_HOST}"
echo "   AMQP Port: ${RABBITMQ_PORT}"
echo "   Management Port: ${RABBITMQ_MGMT_PORT}"
echo "   Max attempts: ${MAX_ATTEMPTS}"
echo "   Wait interval: ${WAIT_INTERVAL}s"

# Function to check if a port is open
check_port() {
    local host=$1
    local port=$2
    local service_name=$3
    
    if nc -z -w3 "$host" "$port" 2>/dev/null; then
        echo "✅ $service_name is accessible on ${host}:${port}"
        return 0
    else
        echo "❌ $service_name is not accessible on ${host}:${port}"
        return 1
    fi
}

# Function to check RabbitMQ health via management API
check_rabbitmq_health() {
    local host=$1
    local port=$2
    
    # Try to get RabbitMQ overview from management API
    if command -v wget >/dev/null 2>&1; then
        if wget -q --timeout=3 --tries=1 "http://${host}:${port}/api/overview" -O /dev/null 2>/dev/null; then
            echo "✅ RabbitMQ management API is responding"
            return 0
        fi
    elif command -v curl >/dev/null 2>&1; then
        if curl -s --connect-timeout 3 "http://${host}:${port}/api/overview" >/dev/null 2>&1; then
            echo "✅ RabbitMQ management API is responding"
            return 0
        fi
    fi
    
    echo "❌ RabbitMQ management API is not responding"
    return 1
}

# Function to check DNS resolution
check_dns() {
    local host=$1
    
    if nslookup "$host" >/dev/null 2>&1; then
        echo "✅ DNS resolution successful for ${host}"
        return 0
    else
        echo "❌ DNS resolution failed for ${host}"
        return 1
    fi
}

# Main waiting loop
attempt=1
while [ $attempt -le $MAX_ATTEMPTS ]; do
    echo ""
    echo "🔄 Attempt ${attempt}/${MAX_ATTEMPTS}"
    
    # Check DNS resolution first
    if check_dns "$RABBITMQ_HOST"; then
        # Check AMQP port
        amqp_ready=false
        if check_port "$RABBITMQ_HOST" "$RABBITMQ_PORT" "RabbitMQ AMQP"; then
            amqp_ready=true
        fi
        
        # Check management port (optional but good for health verification)
        mgmt_ready=false
        if check_port "$RABBITMQ_HOST" "$RABBITMQ_MGMT_PORT" "RabbitMQ Management"; then
            # Try to check actual RabbitMQ health
            if check_rabbitmq_health "$RABBITMQ_HOST" "$RABBITMQ_MGMT_PORT"; then
                mgmt_ready=true
            fi
        fi
        
        # If AMQP port is ready, we can proceed (management port is optional)
        if [ "$amqp_ready" = true ]; then
            echo ""
            echo "🎉 RabbitMQ is ready! Proceeding with application startup..."
            exit 0
        fi
    fi
    
    if [ $attempt -lt $MAX_ATTEMPTS ]; then
        echo "⏳ Waiting ${WAIT_INTERVAL} seconds before next attempt..."
        sleep $WAIT_INTERVAL
    fi
    
    attempt=$((attempt + 1))
done

echo ""
echo "❌ Failed to connect to RabbitMQ after ${MAX_ATTEMPTS} attempts"
echo "   This could indicate:"
echo "   1. RabbitMQ service is not running"
echo "   2. Network connectivity issues"
echo "   3. DNS resolution problems"
echo "   4. RabbitMQ is taking longer than expected to start"
echo ""
echo "💡 Troubleshooting tips:"
echo "   - Check if RabbitMQ container is running: docker ps"
echo "   - Check RabbitMQ logs: docker logs rabbitmq-container-name"
echo "   - Verify network connectivity: docker network ls"
echo "   - Test DNS resolution: nslookup ${RABBITMQ_HOST}"

exit 1