from flask import Flask, jsonify, request
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
import os

app = Flask(__name__)
CORS(app)

# Database configuration
basedir = os.path.abspath(os.path.dirname(__file__))
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL') or \
    'sqlite:///' + os.path.join(basedir, 'data', 'products.db')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

# Models
class Product(db.Model):
    id = db.Column(db.String(50), primary_key=True)
    name = db.Column(db.String(200), nullable=False)
    brand = db.Column(db.String(100), nullable=False)
    price = db.Column(db.Float, nullable=False)
    original_price = db.Column(db.Float)
    image = db.Column(db.String(500))
    rating = db.Column(db.Float, default=0.0)
    rating_count = db.Column(db.Integer, default=0)
    discount = db.Column(db.Integer)
    category = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text)
    stock = db.Column(db.Integer, default=0)

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'brand': self.brand,
            'price': self.price,
            'originalPrice': self.original_price,
            'image': self.image,
            'rating': self.rating,
            'ratingCount': self.rating_count,
            'discount': self.discount,
            'category': self.category,
            'description': self.description,
            'stock': self.stock
        }

# Initialize database
with app.app_context():
    db.create_all()
    
    # Add sample data if no products exist
    if Product.query.count() == 0:
        sample_products = [
            # Men
            Product(id="m-1", name="Classic Cotton Shirt", brand="StyleCraft", price=1299, original_price=2199,
                   image="men-product.jpg", rating=4.3, rating_count=248, discount=41, category="Men",
                   description="A timeless cotton shirt perfect for both casual and formal occasions.", stock=50),
            Product(id="m-2", name="Casual Denim Jeans", brand="StyleCraft", price=1699, original_price=2499,
                   image="men-product-2.jpg", rating=4.2, rating_count=312, discount=32, category="Men",
                   description="Classic denim jeans with a modern fit. Durable and comfortable for everyday wear.", stock=40),
            Product(id="m-3", name="Slim Fit Chinos", brand="UrbanMode", price=1499, original_price=2299,
                   image="product-1.jpg", rating=4.4, rating_count=198, discount=35, category="Men",
                   description="Versatile slim-fit chinos crafted for all-day comfort.", stock=45),

            # Women
            Product(id="w-1", name="Summer Floral Dress", brand="FashionForward", price=1899, original_price=2799,
                   image="women-product-1.jpg", rating=4.6, rating_count=221, discount=32, category="Women",
                   description="Beautiful summer dress with elegant floral patterns for casual outings and parties.", stock=30),
            Product(id="w-2", name="High-Rise Jeans", brand="DenimCo", price=1799, original_price=2599,
                   image="product-2.jpg", rating=4.4, rating_count=356, discount=31, category="Women",
                   description="Flattering high-rise jeans with stretch comfort.", stock=35),

            # Kids
            Product(id="k-1", name="Graphic Tee", brand="Playful", price=599, original_price=899,
                   image="kids-products-1.jpg", rating=4.2, rating_count=140, discount=33, category="Kids",
                   description="Soft cotton tee with a fun graphic print.", stock=80),
            Product(id="k-2", name="Kids Joggers", brand="ActiveKids", price=799, original_price=1199,
                   image="kids-product-2.jpg", rating=4.3, rating_count=96, discount=33, category="Kids",
                   description="Comfy joggers for everyday adventures.", stock=70),
            Product(id="k-3", name="Printed Dress", brand="TinyTrends", price=999, original_price=1499,
                   image="kids-product-3.jpg", rating=4.5, rating_count=122, discount=33, category="Kids",
                   description="Cute printed dress for playful days.", stock=50),

            # Accessories
            Product(id="a-1", name="Leather Belt", brand="Crafted", price=799, original_price=1299,
                   image="accessories-1.jpg", rating=4.2, rating_count=210, discount=38, category="Accessories",
                   description="Genuine leather belt with a classic buckle.", stock=60),
            Product(id="a-2", name="Analog Watch", brand="TimeLine", price=2499, original_price=3999,
                   image="accessories-2.jpg", rating=4.6, rating_count=310, discount=38, category="Accessories",
                   description="Minimal analog watch with a leather strap.", stock=25),
        ]
        
        for product in sample_products:
            db.session.add(product)
        db.session.commit()

# Routes
@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy', 'service': 'product-service'})

@app.route('/products', methods=['GET'])
def get_products():
    try:
        category = request.args.get('category')
        limit = request.args.get('limit', type=int)
        
        query = Product.query
        
        if category:
            query = query.filter(Product.category.ilike(f'%{category}%'))
        
        if limit:
            query = query.limit(limit)
            
        products = query.all()
        result = []
        for product in products:
            p = product.to_dict()
            # Map to UI static paths served by Vite/Nginx from /assets
            if p.get('image'):
                p['image'] = f"/assets/{p['image']}"
            result.append(p)
        return jsonify(result)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/products/<product_id>', methods=['GET'])
def get_product(product_id):
    try:
        product = Product.query.get(product_id)
        if not product:
            return jsonify({'error': 'Product not found'}), 404
        p = product.to_dict()
        if p.get('image'):
            p['image'] = f"/assets/{p['image']}"
        return jsonify(p)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/categories', methods=['GET'])
def get_categories():
    try:
        categories = db.session.query(Product.category).distinct().all()
        return jsonify([cat[0] for cat in categories])
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/products/category/<category>', methods=['GET'])
def get_products_by_category(category):
    try:
        products = Product.query.filter(Product.category.ilike(f'%{category}%')).all()
        result = []
        for product in products:
            p = product.to_dict()
            if p.get('image'):
                p['image'] = f"/assets/{p['image']}"
            result.append(p)
        return jsonify(result)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)