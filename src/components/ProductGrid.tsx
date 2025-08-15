import { useEffect, useState } from "react";
import { API } from "@/lib/utils";
import ProductCard from "./ProductCard";
import type { Product } from "@/context/CartContext";

interface ProductGridProps {
  title?: string;
  category?: string;
  limit?: number;
}

const ProductGrid = ({ title = "Featured Products", category, limit }: ProductGridProps) => {
  const [items, setItems] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const controller = new AbortController();
    setLoading(true);
    setError(null);
    const params = new URLSearchParams();
    if (category) params.set('category', category);
    if (limit) params.set('limit', String(limit));
    fetch(`${API.productService}/products?${params.toString()}`, { signal: controller.signal })
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
  }, [category, limit]);

  return (
    <section className="py-12">
      <div className="container mx-auto px-4">
        <div className="text-center mb-8">
          <h2 className="text-3xl font-bold text-foreground mb-2">{title}</h2>
          <p className="text-muted-foreground">Discover our handpicked collection of premium products</p>
        </div>

        {loading ? (
          <div className="text-center text-muted-foreground">Loading...</div>
        ) : error ? (
          <div className="text-center text-red-600">{error}</div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {items.map((product) => (
              <ProductCard key={product.id} {...product} />
            ))}
          </div>
        )}
      </div>
    </section>
  );
};

export default ProductGrid;