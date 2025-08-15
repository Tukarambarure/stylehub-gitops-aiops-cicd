import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { useNavigate } from "react-router-dom";

const categories = [
  {
    id: "men",
    name: "Men's Fashion",
    description: "Trendy outfits for the modern man",
    icon: "👔",
  },
  {
    id: "women",
    name: "Women's Fashion",
    description: "Elegant styles for every occasion",
    icon: "👗",
  },
  {
    id: "kids",
    name: "Kids Collection",
    description: "Comfortable and playful designs",
    icon: "👶",
  },
  {
    id: "accessories",
    name: "Accessories",
    description: "Complete your look with style",
    icon: "👜",
  },
  {
    id: "footwear",
    name: "Footwear",
    description: "Step out in comfort and style",
    icon: "👟",
  },
  {
    id: "sports",
    name: "Sports & Fitness",
    description: "Gear up for your active lifestyle",
    icon: "⚽",
  },
];

const Categories = () => {
  const navigate = useNavigate();
  return (
    <section className="py-12 bg-gradient-secondary">
      <div className="container mx-auto px-4">
        <div className="text-center mb-8">
          <h2 className="text-3xl font-bold text-foreground mb-2">Shop by Category</h2>
          <p className="text-muted-foreground">Find exactly what you're looking for</p>
        </div>

        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
          {categories.map((category) => (
            <Card
              key={category.id}
              className="group cursor-pointer border-0 shadow-soft hover:shadow-medium transition-smooth bg-background/80 backdrop-blur-sm"
              onClick={() => navigate(`/category/${category.id}`)}
            >
              <CardContent className="p-6 text-center">
                <div className="text-4xl mb-3 group-hover:scale-110 transition-smooth">
                  {category.icon}
                </div>
                <h3 className="font-semibold text-foreground mb-1 text-sm">
                  {category.name}
                </h3>
                <p className="text-xs text-muted-foreground mb-3">
                  {category.description}
                </p>
                <Button 
                  variant="outline" 
                  size="sm" 
                  className="w-full"
                  onClick={(e) => {
                    e.stopPropagation();
                    navigate(`/category/${category.id}`);
                  }}
                >
                  Explore
                </Button>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    </section>
  );
};

export default Categories;