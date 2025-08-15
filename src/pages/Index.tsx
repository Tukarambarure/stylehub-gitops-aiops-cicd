import Header from "@/components/Header";
import HeroSection from "@/components/HeroSection";
import Categories from "@/components/Categories";
import ProductGrid from "@/components/ProductGrid";
import Footer from "@/components/Footer";

const Index = () => {
  return (
    <div className="min-h-screen bg-background">
      <Header />
      <main>
        <HeroSection />
        <Categories />
        <ProductGrid title="Featured Products" limit={8} />
        <section className="py-12 bg-gradient-secondary">
          <div className="container mx-auto px-4 text-center">
            <h2 className="text-3xl font-bold text-foreground mb-4">
              Why Choose StyleHub?
            </h2>
            <div className="grid md:grid-cols-3 gap-8 mt-8">
              <div className="p-6">
                <div className="text-4xl mb-4">🚚</div>
                <h3 className="font-semibold mb-2">Free Shipping</h3>
                <p className="text-muted-foreground">Free shipping on orders above ₹999</p>
              </div>
              <div className="p-6">
                <div className="text-4xl mb-4">🔄</div>
                <h3 className="font-semibold mb-2">Easy Returns</h3>
                <p className="text-muted-foreground">30-day hassle-free return policy</p>
              </div>
              <div className="p-6">
                <div className="text-4xl mb-4">💯</div>
                <h3 className="font-semibold mb-2">100% Authentic</h3>
                <p className="text-muted-foreground">Genuine products from trusted brands</p>
              </div>
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </div>
  );
};

export default Index;
