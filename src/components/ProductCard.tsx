import { Heart, Star } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { useCart } from "@/context/CartContext";
import { useToast } from "@/hooks/use-toast";
import { useNavigate } from "react-router-dom";

interface ProductCardProps {
  id: string;
  name: string;
  brand: string;
  price: number;
  originalPrice?: number;
  image: string;
  rating: number;
  ratingCount: number;
  discount?: number;
}

const ProductCard = ({
  id,
  name,
  brand,
  price,
  originalPrice,
  image,
  rating,
  ratingCount,
  discount,
}: ProductCardProps) => {
  const { dispatch } = useCart();
  const { toast } = useToast();
  const navigate = useNavigate();

  const handleAddToCart = (e: React.MouseEvent) => {
    e.stopPropagation();
    dispatch({ 
      type: 'ADD_ITEM', 
      payload: { id, name, brand, price, originalPrice, image, rating, ratingCount, discount, category: '', description: '' }
    });
    toast({
      title: "Added to cart!",
      description: `${name} has been added to your cart.`,
    });
  };

  const handleCardClick = () => {
    navigate(`/product/${id}`);
  };
  return (
    <Card 
      className="group cursor-pointer border-0 shadow-soft hover:shadow-medium transition-smooth overflow-hidden"
      onClick={handleCardClick}
    >
      <CardContent className="p-0">
        {/* Product Image */}
        <div className="relative overflow-hidden aspect-square">
          <img
            src={image}
            alt={name}
            className="w-full h-full object-cover group-hover:scale-105 transition-smooth"
          />
          {discount && (
            <div className="absolute top-2 left-2 bg-primary text-primary-foreground px-2 py-1 rounded text-xs font-semibold">
              {discount}% OFF
            </div>
          )}
          <Button
            variant="ghost"
            size="icon"
            className="absolute top-2 right-2 bg-background/80 hover:bg-background transition-smooth"
            onClick={(e) => e.stopPropagation()}
          >
            <Heart className="h-4 w-4" />
          </Button>
        </div>

        {/* Product Info */}
        <div className="p-4">
          <div className="space-y-2">
            <div>
              <h3 className="font-semibold text-foreground line-clamp-1">{name}</h3>
              <p className="text-sm text-muted-foreground">{brand}</p>
            </div>

            {/* Rating */}
            <div className="flex items-center gap-1">
              <div className="flex items-center">
                <Star className="h-3 w-3 fill-yellow-400 text-yellow-400" />
                <span className="text-xs text-foreground ml-1">{rating}</span>
              </div>
              <span className="text-xs text-muted-foreground">({ratingCount})</span>
            </div>

            {/* Price */}
            <div className="flex items-center gap-2">
              <span className="text-lg font-bold text-foreground">₹{price}</span>
              {originalPrice && (
                <span className="text-sm text-muted-foreground line-through">₹{originalPrice}</span>
              )}
            </div>

            {/* Add to Cart */}
            <Button variant="cart" size="sm" className="w-full mt-3" onClick={handleAddToCart}>
              Add to Cart
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  );
};

export default ProductCard;