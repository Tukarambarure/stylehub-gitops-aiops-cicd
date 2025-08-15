import { Search, ShoppingBag, User, Heart } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useCart } from "@/context/CartContext";
import { useAuth } from "@/context/AuthContext";
import { useNavigate } from "react-router-dom";

const Header = () => {
  const { state } = useCart();
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  return (
    <header className="bg-background border-b border-border sticky top-0 z-50 backdrop-blur-sm bg-background/95">
      <div className="container mx-auto px-4 py-4">
        <div className="flex items-center justify-between">
          {/* Logo */}
          <div className="flex items-center cursor-pointer" onClick={() => navigate('/')}>
            <h1 className="text-2xl font-bold bg-gradient-primary bg-clip-text text-transparent">
              StyleHub
            </h1>
          </div>

          {/* Navigation */}
          <nav className="hidden md:flex items-center space-x-8">
            <button 
              onClick={() => navigate('/category/men')}
              className="text-foreground hover:text-primary transition-smooth font-medium"
            >
              Men
            </button>
            <button 
              onClick={() => navigate('/category/women')}
              className="text-foreground hover:text-primary transition-smooth font-medium"
            >
              Women
            </button>
            <button 
              onClick={() => navigate('/category/kids')}
              className="text-foreground hover:text-primary transition-smooth font-medium"
            >
              Kids
            </button>
            <button 
              onClick={() => navigate('/category/accessories')}
              className="text-foreground hover:text-primary transition-smooth font-medium"
            >
              Accessories
            </button>
          </nav>

          {/* Search Bar */}
          <div className="hidden md:flex items-center max-w-md flex-1 mx-8">
            <div className="relative w-full">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground h-4 w-4" />
              <Input
                placeholder="Search for products, brands and more"
                className="pl-10 pr-4 w-full"
              />
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex items-center space-x-4">
            <Button variant="ghost" size="icon" className="relative">
              <Heart className="h-5 w-5" />
            </Button>
            <Button 
              variant="ghost" 
              size="icon" 
              className="relative"
              onClick={() => navigate('/cart')}
            >
              <ShoppingBag className="h-5 w-5" />
              {state.itemCount > 0 && (
                <span className="absolute -top-1 -right-1 bg-primary text-primary-foreground text-xs rounded-full h-5 w-5 flex items-center justify-center">
                  {state.itemCount}
                </span>
              )}
            </Button>
            {user ? (
              <div className="flex items-center gap-2">
                <span className="text-sm">Hi, {user.firstName || user.email}</span>
                <Button variant="outline" onClick={logout}>Logout</Button>
              </div>
            ) : (
              <Button variant="ghost" size="icon" onClick={() => navigate('/login')}>
                <User className="h-5 w-5" />
              </Button>
            )}
          </div>
        </div>

        {/* Mobile Search */}
        <div className="md:hidden mt-4">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground h-4 w-4" />
            <Input
              placeholder="Search for products, brands and more"
              className="pl-10 pr-4 w-full"
            />
          </div>
        </div>
      </div>
    </header>
  );
};

export default Header;