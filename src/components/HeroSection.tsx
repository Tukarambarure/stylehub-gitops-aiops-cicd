import { Button } from "@/components/ui/button";
import heroBanner from "@/assets/hero-banner.jpg";

const HeroSection = () => {
  return (
    <section className="relative overflow-hidden bg-gradient-secondary">
      <div className="container mx-auto px-4 py-12 md:py-20">
        <div className="grid md:grid-cols-2 gap-8 items-center">
          {/* Content */}
          <div className="space-y-6">
            <div className="space-y-4">
              <h1 className="text-4xl md:text-6xl font-bold text-foreground leading-tight">
                Fashion That{" "}
                <span className="bg-gradient-primary bg-clip-text text-transparent">
                  Defines You
                </span>
              </h1>
              <p className="text-lg text-muted-foreground max-w-md">
                Discover the latest trends in fashion with our curated collection of premium clothing, 
                accessories, and lifestyle products.
              </p>
            </div>
            
            <div className="flex gap-4">
              <Button variant="hero" size="lg">
                Shop Now
              </Button>
              <Button variant="outline" size="lg">
                Explore Collection
              </Button>
            </div>

            {/* Stats */}
            <div className="flex gap-8 pt-6 border-t border-border">
              <div>
                <div className="text-2xl font-bold text-foreground">10K+</div>
                <div className="text-sm text-muted-foreground">Happy Customers</div>
              </div>
              <div>
                <div className="text-2xl font-bold text-foreground">500+</div>
                <div className="text-sm text-muted-foreground">Premium Brands</div>
              </div>
              <div>
                <div className="text-2xl font-bold text-foreground">99%</div>
                <div className="text-sm text-muted-foreground">Satisfaction Rate</div>
              </div>
            </div>
          </div>

          {/* Hero Image */}
          <div className="relative">
            <div className="relative overflow-hidden rounded-2xl shadow-strong">
              <img
                src={heroBanner}
                alt="Fashion Collection"
                className="w-full h-[400px] md:h-[500px] object-cover"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black/20 to-transparent" />
            </div>
            {/* Floating Elements */}
            <div className="absolute -top-4 -right-4 bg-background p-4 rounded-full shadow-medium">
              <div className="text-center">
                <div className="text-sm font-semibold text-primary">50%</div>
                <div className="text-xs text-muted-foreground">OFF</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default HeroSection;