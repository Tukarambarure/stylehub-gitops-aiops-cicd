from flask import Flask, jsonify, request
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
import os
import requests

app = Flask(__name__)
CORS(app)

# Configuration
basedir = os.path.abspath(os.path.dirname(__file__))
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL') or \
    'sqlite:///' + os.path.join(basedir, 'data', 'cart.db')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# Service URLs
PRODUCT_SERVICE_URL = os.environ.get('PRODUCT_SERVICE_URL') or 'http://localhost:5001'

db = SQLAlchemy(app)

# Models
class CartItem(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.String(50), nullable=False)
    product_id = db.Column(db.String(50), nullable=False)
    quantity = db.Column(db.Integer, nullable=False, default=1)
    added_at = db.Column(db.DateTime, default=db.func.current_timestamp())

    def to_dict(self):
        return {
            'id': self.id,
            'userId': self.user_id,
            'productId': self.product_id,
            'quantity': self.quantity,
            'addedAt': self.added_at.isoformat() if self.added_at else None
        }

# Initialize database
with app.app_context():
    db.create_all()

# Helper functions
def get_product_details(product_id):
    try:
        response = requests.get(f'{PRODUCT_SERVICE_URL}/products/{product_id}')
        if response.status_code == 200:
            return response.json()
        return None
    except:
        return None

# Routes
@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy', 'service': 'cart-service'})

@app.route('/cart/<user_id>', methods=['GET'])
def get_cart(user_id):
    try:
        cart_items = CartItem.query.filter_by(user_id=user_id).all()
        
        # Enrich cart items with product details
        enriched_items = []
        total = 0
        
        for item in cart_items:
            product = get_product_details(item.product_id)
            if product:
                item_total = product['price'] * item.quantity
                total += item_total
                
                enriched_items.append({
                    'id': item.id,
                    'product': product,
                    'quantity': item.quantity,
                    'itemTotal': item_total,
                    'addedAt': item.added_at.isoformat() if item.added_at else None
                })
        
        return jsonify({
            'items': enriched_items,
            'total': total,
            'itemCount': sum(item.quantity for item in cart_items)
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/cart/<user_id>/add', methods=['POST'])
def add_to_cart(user_id):
    try:
        data = request.get_json()
        
        if 'productId' not in data:
            return jsonify({'error': 'Product ID is required'}), 400
        
        product_id = data['productId']
        quantity = data.get('quantity', 1)
        
        # Verify product exists
        product = get_product_details(product_id)
        if not product:
            return jsonify({'error': 'Product not found'}), 404
        
        # Check if item already exists in cart
        existing_item = CartItem.query.filter_by(
            user_id=user_id, 
            product_id=product_id
        ).first()
        
        if existing_item:
            existing_item.quantity += quantity
        else:
            new_item = CartItem(
                user_id=user_id,
                product_id=product_id,
                quantity=quantity
            )
            db.session.add(new_item)
        
        db.session.commit()
        
        return jsonify({'message': 'Item added to cart successfully'}), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/cart/<user_id>/update', methods=['PUT'])
def update_cart_item(user_id):
    try:
        data = request.get_json()
        
        if 'itemId' not in data or 'quantity' not in data:
            return jsonify({'error': 'Item ID and quantity are required'}), 400
        
        item = CartItem.query.filter_by(
            id=data['itemId'], 
            user_id=user_id
        ).first()
        
        if not item:
            return jsonify({'error': 'Cart item not found'}), 404
        
        if data['quantity'] <= 0:
            db.session.delete(item)
        else:
            item.quantity = data['quantity']
        
        db.session.commit()
        
        return jsonify({'message': 'Cart updated successfully'})
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/cart/<user_id>/remove/<int:item_id>', methods=['DELETE'])
def remove_from_cart(user_id, item_id):
    try:
        item = CartItem.query.filter_by(
            id=item_id, 
            user_id=user_id
        ).first()
        
        if not item:
            return jsonify({'error': 'Cart item not found'}), 404
        
        db.session.delete(item)
        db.session.commit()
        
        return jsonify({'message': 'Item removed from cart'})
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/cart/<user_id>/clear', methods=['DELETE'])
def clear_cart(user_id):
    try:
        CartItem.query.filter_by(user_id=user_id).delete()
        db.session.commit()
        
        return jsonify({'message': 'Cart cleared successfully'})
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5003, debug=True)