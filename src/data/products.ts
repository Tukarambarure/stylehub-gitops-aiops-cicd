import men1 from "@/assets/men-product.jpg";
import men2 from "@/assets/men-product-2.jpg";
import women1 from "@/assets/women-product-1.jpg";
import kids1 from "@/assets/kids-products-1.jpg";
import kids2 from "@/assets/kids-product-2.jpg";
import kids3 from "@/assets/kids-product-3.jpg";
import acc1 from "@/assets/accessories-1.jpg";
import acc2 from "@/assets/accessories-2.jpg";
import product1 from "@/assets/product-1.jpg";
import product2 from "@/assets/product-2.jpg";

export interface Product {
  id: string;
  name: string;
  brand: string;
  price: number;
  originalPrice?: number;
  image: string;
  rating: number;
  ratingCount: number;
  discount?: number;
  category: string;
  description: string;
}

export const products: Product[] = [
  // Men
  {
    id: "m-1",
    name: "Classic Cotton Shirt",
    brand: "StyleCraft",
    price: 1299,
    originalPrice: 2199,
    image: men1,
    rating: 4.3,
    ratingCount: 248,
    discount: 41,
    category: "Men",
    description: "A timeless cotton shirt perfect for both casual and formal occasions.",
  },
  {
    id: "m-2",
    name: "Casual Denim Jeans",
    brand: "StyleCraft",
    price: 1699,
    originalPrice: 2499,
    image: men2,
    rating: 4.2,
    ratingCount: 312,
    discount: 32,
    category: "Men",
    description: "Classic denim jeans with a modern fit. Durable and comfortable for everyday wear.",
  },
  {
    id: "m-3",
    name: "Slim Fit Chinos",
    brand: "UrbanMode",
    price: 1499,
    originalPrice: 2299,
    image: product1,
    rating: 4.4,
    ratingCount: 198,
    discount: 35,
    category: "Men",
    description: "Versatile slim-fit chinos crafted for all-day comfort.",
  },

  // Women
  {
    id: "w-1",
    name: "Summer Floral Dress",
    brand: "FashionForward",
    price: 1899,
    originalPrice: 2799,
    image: women1,
    rating: 4.6,
    ratingCount: 221,
    discount: 32,
    category: "Women",
    description: "Beautiful summer dress with elegant floral patterns for casual outings and parties.",
  },
  {
    id: "w-2",
    name: "High-Rise Jeans",
    brand: "DenimCo",
    price: 1799,
    originalPrice: 2599,
    image: product2,
    rating: 4.4,
    ratingCount: 356,
    discount: 31,
    category: "Women",
    description: "Flattering high-rise jeans with stretch comfort.",
  },

  // Kids
  {
    id: "k-1",
    name: "Graphic Tee",
    brand: "Playful",
    price: 599,
    originalPrice: 899,
    image: kids1,
    rating: 4.2,
    ratingCount: 140,
    discount: 33,
    category: "Kids",
    description: "Soft cotton tee with a fun graphic print.",
  },
  {
    id: "k-2",
    name: "Kids Joggers",
    brand: "ActiveKids",
    price: 799,
    originalPrice: 1199,
    image: kids2,
    rating: 4.3,
    ratingCount: 96,
    discount: 33,
    category: "Kids",
    description: "Comfy joggers for everyday adventures.",
  },
  {
    id: "k-3",
    name: "Printed Dress",
    brand: "TinyTrends",
    price: 999,
    originalPrice: 1499,
    image: kids3,
    rating: 4.5,
    ratingCount: 122,
    discount: 33,
    category: "Kids",
    description: "Cute printed dress for playful days.",
  },

  // Accessories
  {
    id: "a-1",
    name: "Leather Belt",
    brand: "Crafted",
    price: 799,
    originalPrice: 1299,
    image: acc1,
    rating: 4.2,
    ratingCount: 210,
    discount: 38,
    category: "Accessories",
    description: "Genuine leather belt with a classic buckle.",
  },
  {
    id: "a-2",
    name: "Analog Watch",
    brand: "TimeLine",
    price: 2499,
    originalPrice: 3999,
    image: acc2,
    rating: 4.6,
    ratingCount: 310,
    discount: 38,
    category: "Accessories",
    description: "Minimal analog watch with a leather strap.",
  },
];