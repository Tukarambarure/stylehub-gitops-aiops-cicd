from flask import Flask, jsonify, request
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
import os
import requests
import uuid
from datetime import datetime

app = Flask(__name__)
CORS(app)

# Configuration
basedir = os.path.abspath(os.path.dirname(__file__))
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL') or \
    'sqlite:///' + os.path.join(basedir, 'data', 'orders.db')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# Service URLs
CART_SERVICE_URL = os.environ.get('CART_SERVICE_URL') or 'http://localhost:5003'
USER_SERVICE_URL = os.environ.get('USER_SERVICE_URL') or 'http://localhost:5002'

db = SQLAlchemy(app)

# Models
class Order(db.Model):
    id = db.Column(db.String(50), primary_key=True)
    user_id = db.Column(db.String(50), nullable=False)
    total_amount = db.Column(db.Float, nullable=False)
    status = db.Column(db.String(50), default='pending')
    payment_method = db.Column(db.String(50))
    shipping_address = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=db.func.current_timestamp())
    updated_at = db.Column(db.DateTime, default=db.func.current_timestamp(), onupdate=db.func.current_timestamp())

    def to_dict(self):
        return {
            'id': self.id,
            'userId': self.user_id,
            'totalAmount': self.total_amount,
            'status': self.status,
            'paymentMethod': self.payment_method,
            'shippingAddress': self.shipping_address,
            'createdAt': self.created_at.isoformat() if self.created_at else None,
            'updatedAt': self.updated_at.isoformat() if self.updated_at else None
        }

class OrderItem(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    order_id = db.Column(db.String(50), db.ForeignKey('order.id'), nullable=False)
    product_id = db.Column(db.String(50), nullable=False)
    product_name = db.Column(db.String(200), nullable=False)
    product_price = db.Column(db.Float, nullable=False)
    quantity = db.Column(db.Integer, nullable=False)
    item_total = db.Column(db.Float, nullable=False)

    def to_dict(self):
        return {
            'id': self.id,
            'orderId': self.order_id,
            'productId': self.product_id,
            'productName': self.product_name,
            'productPrice': self.product_price,
            'quantity': self.quantity,
            'itemTotal': self.item_total
        }

# Initialize database
with app.app_context():
    db.create_all()

# Helper functions
def get_cart_details(user_id):
    try:
        response = requests.get(f'{CART_SERVICE_URL}/cart/{user_id}')
        if response.status_code == 200:
            return response.json()
        return None
    except:
        return None

def clear_user_cart(user_id):
    try:
        requests.delete(f'{CART_SERVICE_URL}/cart/{user_id}/clear')
    except:
        pass

# Routes
@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy', 'service': 'order-service'})

@app.route('/orders', methods=['POST'])
def create_order():
    try:
        data = request.get_json()
        
        required_fields = ['userId', 'paymentMethod', 'shippingAddress']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'{field} is required'}), 400
        
        user_id = data['userId']
        
        # Get cart details
        cart = get_cart_details(user_id)
        if not cart or not cart['items']:
            return jsonify({'error': 'Cart is empty'}), 400
        
        # Create order
        order_id = str(uuid.uuid4())
        order = Order(
            id=order_id,
            user_id=user_id,
            total_amount=cart['total'],
            payment_method=data['paymentMethod'],
            shipping_address=data['shippingAddress'],
            status='pending'
        )
        
        db.session.add(order)
        
        # Create order items
        for cart_item in cart['items']:
            order_item = OrderItem(
                order_id=order_id,
                product_id=cart_item['product']['id'],
                product_name=cart_item['product']['name'],
                product_price=cart_item['product']['price'],
                quantity=cart_item['quantity'],
                item_total=cart_item['itemTotal']
            )
            db.session.add(order_item)
        
        db.session.commit()
        
        # Clear cart after successful order
        clear_user_cart(user_id)
        
        return jsonify({
            'message': 'Order created successfully',
            'order': order.to_dict()
        }), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/orders/<user_id>', methods=['GET'])
def get_user_orders(user_id):
    try:
        orders = Order.query.filter_by(user_id=user_id).order_by(Order.created_at.desc()).all()
        
        orders_with_items = []
        for order in orders:
            order_items = OrderItem.query.filter_by(order_id=order.id).all()
            order_dict = order.to_dict()
            order_dict['items'] = [item.to_dict() for item in order_items]
            orders_with_items.append(order_dict)
        
        return jsonify(orders_with_items)
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/orders/detail/<order_id>', methods=['GET'])
def get_order_details(order_id):
    try:
        order = Order.query.get(order_id)
        if not order:
            return jsonify({'error': 'Order not found'}), 404
        
        order_items = OrderItem.query.filter_by(order_id=order_id).all()
        
        order_dict = order.to_dict()
        order_dict['items'] = [item.to_dict() for item in order_items]
        
        return jsonify(order_dict)
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/orders/<order_id>/status', methods=['PUT'])
def update_order_status(order_id):
    try:
        data = request.get_json()
        
        if 'status' not in data:
            return jsonify({'error': 'Status is required'}), 400
        
        order = Order.query.get(order_id)
        if not order:
            return jsonify({'error': 'Order not found'}), 404
        
        order.status = data['status']
        order.updated_at = datetime.utcnow()
        db.session.commit()
        
        return jsonify({
            'message': 'Order status updated successfully',
            'order': order.to_dict()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5004, debug=True)