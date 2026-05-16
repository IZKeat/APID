
export interface Product {
  id: number;
  name: string;
  price: number;
  image: string;
  category: string;
}

export interface CartItem extends Product {
  quantity: number;
  uuid: string; // Unique ID for list animations
}

export type Category = 'All' | 'Rice' | 'Noodles' | 'Drinks' | 'Snacks' | 'Western';

export type ViewType = 'POS' | 'PROFILE' | 'LIBRARY' | 'ACCESS' | 'ATTENDANCE';
