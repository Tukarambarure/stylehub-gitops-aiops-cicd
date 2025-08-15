import { useParams } from 'react-router-dom';
import { useEffect, useState } from 'react';
import { API } from '@/lib/utils';
import type { Product } from '@/context/CartContext';
import ProductCard from '@/components/ProductCard';
import Header from '@/components/Header';
import Footer from '@/components/Footer';

const CategoryPage = () => {
  const { category } = useParams();
  
  const [items, setItems] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const controller = new AbortController();
    setLoading(true);
    setError(null);
    fetch(`${API.productService}/products?category=${encodeURIComponent(category || '')}`, { signal: controller.signal })
      .then(async (r) => {
        const data = await r.json();
        if (!r.ok) throw new Error(data?.error || 'Failed to load products');
        setItems(data);
      })
      .catch((e) => {
        if (e.name !== 'AbortError') setError(e.message || 'Error');
      })
      .finally(() => setLoading(false));
    return () => controller.abort();
  }, [category]);

  const categoryTitle = category ? 
    category.charAt(0).toUpperCase() + category.slice(1) : 
    'All Products';

  return (
    <div className="min-h-screen bg-background">
      <Header />
      
      <main className="container mx-auto px-4 py-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-foreground mb-2">
            {categoryTitle}
          </h1>
          <p className="text-muted-foreground">
            {items.length} products found
          </p>
        </div>

        {loading ? (
          <div className="text-center text-muted-foreground">Loading...</div>
        ) : error ? (
          <div className="text-center text-red-600">{error}</div>
        ) : items.length === 0 ? (
          <div className="text-center py-20">
            <h2 className="text-xl font-semibold text-foreground mb-2">No products found</h2>
            <p className="text-muted-foreground">Try browsing other categories or check back later.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {items.map((product) => (
              <ProductCard key={product.id} {...product} />
            ))}
          </div>
        )}
      </main>
      
      <Footer />
    </div>
  );
};

export default CategoryPage;