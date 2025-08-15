import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export const API = {
  productService: import.meta.env.VITE_PRODUCT_SERVICE_URL || 'http://localhost:5001',
  userService: import.meta.env.VITE_USER_SERVICE_URL || 'http://localhost:5002',
  cartService: import.meta.env.VITE_CART_SERVICE_URL || 'http://localhost:5003',
  orderService: import.meta.env.VITE_ORDER_SERVICE_URL || 'http://localhost:5004',
};
