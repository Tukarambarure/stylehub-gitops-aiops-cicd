import { Facebook, Instagram, Twitter, Youtube } from "lucide-react";

const Footer = () => {
  return (
    <footer className="bg-foreground text-background">
      <div className="container mx-auto px-4 py-12">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          {/* Brand */}
          <div className="space-y-4">
            <h3 className="text-2xl font-bold">StyleHub</h3>
            <p className="text-background/80">
              Your ultimate destination for premium fashion and lifestyle products.
            </p>
            <div className="flex space-x-4">
              <Facebook className="h-5 w-5 text-background/60 hover:text-background cursor-pointer transition-smooth" />
              <Instagram className="h-5 w-5 text-background/60 hover:text-background cursor-pointer transition-smooth" />
              <Twitter className="h-5 w-5 text-background/60 hover:text-background cursor-pointer transition-smooth" />
              <Youtube className="h-5 w-5 text-background/60 hover:text-background cursor-pointer transition-smooth" />
            </div>
          </div>

          {/* Quick Links */}
          <div>
            <h4 className="font-semibold mb-4">Quick Links</h4>
            <ul className="space-y-2">
              <li><a href="#" className="text-background/80 hover:text-background transition-smooth">About Us</a></li>
              <li><a href="#" className="text-background/80 hover:text-background transition-smooth">Contact</a></li>
              <li><a href="#" className="text-background/80 hover:text-background transition-smooth">Size Guide</a></li>
              <li><a href="#" className="text-background/80 hover:text-background transition-smooth">Returns</a></li>
            </ul>
          </div>

          {/* Categories */}
          <div>
            <h4 className="font-semibold mb-4">Categories</h4>
            <ul className="space-y-2">
              <li><a href="#" className="text-background/80 hover:text-background transition-smooth">Men's Fashion</a></li>
              <li><a href="#" className="text-background/80 hover:text-background transition-smooth">Women's Fashion</a></li>
              <li><a href="#" className="text-background/80 hover:text-background transition-smooth">Kids Collection</a></li>
              <li><a href="#" className="text-background/80 hover:text-background transition-smooth">Accessories</a></li>
            </ul>
          </div>

          {/* Customer Service */}
          <div>
            <h4 className="font-semibold mb-4">Customer Service</h4>
            <ul className="space-y-2">
              <li><a href="#" className="text-background/80 hover:text-background transition-smooth">Help Center</a></li>
              <li><a href="#" className="text-background/80 hover:text-background transition-smooth">Track Order</a></li>
              <li><a href="#" className="text-background/80 hover:text-background transition-smooth">Shipping Info</a></li>
              <li><a href="#" className="text-background/80 hover:text-background transition-smooth">Support</a></li>
            </ul>
          </div>
        </div>

        <div className="border-t border-background/20 mt-8 pt-8 text-center">
          <p className="text-background/60">
            © 2024 StyleHub. All rights reserved. | Privacy Policy | Terms of Service
          </p>
        </div>
      </div>
    </footer>
  );
};

export default Footer;