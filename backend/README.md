# StyleHub E-commerce Backend - Microservices Architecture

This backend consists of 4 microservices built with Python Flask:

## Microservices:

1. **Product Service** (Port 5001) - Manages product catalog, categories, and inventory
2. **User Service** (Port 5002) - Handles user authentication, profiles, and management
3. **Cart Service** (Port 5003) - Manages shopping cart operations and session management
4. **Order Service** (Port 5004) - Processes orders, payments, and order tracking

## Setup Instructions:

### Prerequisites:
- Docker and Docker Compose installed
- Python 3.9+ (for local development)

### Quick Start with Docker:
```bash
# Clone the repository
cd backend

# Build and run all microservices
docker-compose up --build

# The services will be available at:
# Product Service: http://localhost:5001
# User Service: http://localhost:5002
# Cart Service: http://localhost:5003
# Order Service: http://localhost:5004
```

### Local Development:
```bash
# For each service directory
cd product-service
pip install -r requirements.txt
python app.py
```

## API Endpoints:

### Product Service (5001):
- GET /products - Get all products
- GET /products/{id} - Get product by ID
- GET /categories - Get all categories
- GET /products/category/{category} - Get products by category

### User Service (5002):
- POST /auth/register - Register new user
- POST /auth/login - User login
- GET /users/profile/{id} - Get user profile
- PUT /users/profile/{id} - Update user profile

### Cart Service (5003):
- GET /cart/{user_id} - Get user cart
- POST /cart/{user_id}/add - Add item to cart
- PUT /cart/{user_id}/update - Update cart item
- DELETE /cart/{user_id}/remove/{item_id} - Remove item from cart

### Order Service (5004):
- POST /orders - Create new order
- GET /orders/{user_id} - Get user orders
- GET /orders/{order_id} - Get order details
- PUT /orders/{order_id}/status - Update order status

## Database:
Each service uses SQLite for simplicity. In production, consider PostgreSQL or MongoDB.

## Frontend Integration:
Update the frontend API calls to point to these services at:
- http://localhost:5001 (Product Service)
- http://localhost:5002 (User Service)
- http://localhost:5003 (Cart Service)
- http://localhost:5004 (Order Service)

To run the full stack including the UI, use the root-level docker compose file.