
import { Product } from './types';
import { Utensils, Coffee, Pizza, Sandwich } from 'lucide-react';
import React from 'react';

// Using consistent placeholder images but keeping the vibe close to the screenshot
// Ideally, we'd use icons, but prompt requested picsum.
export const PRODUCTS: Product[] = [
  {
    id: 1,
    name: 'Chicken Rice',
    price: 7.00,
    category: 'Rice',
    image: 'https://picsum.photos/id/292/200/200',
  },
  {
    id: 2,
    name: 'Nasi Lemak',
    price: 6.50,
    category: 'Rice',
    image: 'https://picsum.photos/id/493/200/200',
  },
  {
    id: 3,
    name: 'Milo Ice',
    price: 2.50,
    category: 'Drinks',
    image: 'https://picsum.photos/id/431/200/200',
  },
  {
    id: 4,
    name: 'Teh Tarik',
    price: 2.20,
    category: 'Drinks',
    image: 'https://picsum.photos/id/1060/200/200',
  },
  {
    id: 5,
    name: 'Fried Rice',
    price: 8.00,
    category: 'Rice',
    image: 'https://picsum.photos/id/488/200/200',
  },
  {
    id: 6,
    name: 'Mee Goreng',
    price: 7.50,
    category: 'Noodles',
    image: 'https://picsum.photos/id/75/200/200',
  },
  {
    id: 7,
    name: 'Chicken Chop',
    price: 12.00,
    category: 'Western',
    image: 'https://picsum.photos/id/835/200/200',
  },
  {
    id: 8,
    name: 'Curry Puff',
    price: 1.80,
    category: 'Snacks',
    image: 'https://picsum.photos/id/225/200/200',
  },
   {
    id: 9,
    name: 'Ice Lemon Tea',
    price: 3.00,
    category: 'Drinks',
    image: 'https://picsum.photos/id/999/200/200',
  },
];

export const CATEGORIES = ['All', 'Rice', 'Noodles', 'Drinks', 'Western', 'Snacks'];

export const ANIMATION_SPRING = {
  type: "spring" as const,
  stiffness: 400,
  damping: 17
};

export const ANIMATION_BOUNCE = {
  type: "spring" as const,
  stiffness: 300,
  damping: 10
};
