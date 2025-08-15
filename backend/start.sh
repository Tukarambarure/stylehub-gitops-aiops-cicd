#!/bin/bash

# Make script executable
chmod +x backend/start.sh

# StyleHub E-commerce Backend Startup Script

echo "🚀 Starting StyleHub Microservices..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Create data directories
echo "📁 Creating data directories..."
mkdir -p product-service/data
mkdir -p user-service/data
mkdir -p cart-service/data
mkdir -p order-service/data

# Build and start all services
echo "🔧 Building and starting microservices..."
docker-compose up --build -d

# Wait for services to start
echo "⏳ Waiting for services to initialize..."
sleep 10

# Check service health
echo "🏥 Checking service health..."

services=("product-service:5001" "user-service:5002" "cart-service:5003" "order-service:5004")

for service in "${services[@]}"; do
    name=${service%:*}
    port=${service#*:}
    
    if curl -f -s http://localhost:$port/health > /dev/null; then
        echo "✅ $name is healthy (port $port)"
    else
        echo "❌ $name is not responding (port $port)"
    fi
done

echo ""
echo "🎉 StyleHub Backend is ready!"
echo ""
echo "📡 API Endpoints:"
echo "   Product Service: http://localhost:5001"
echo "   User Service:    http://localhost:5002"
echo "   Cart Service:    http://localhost:5003"
echo "   Order Service:   http://localhost:5004"
echo ""
echo "📚 API Documentation available in README.md"
echo ""
echo "🛑 To stop all services: docker-compose down"