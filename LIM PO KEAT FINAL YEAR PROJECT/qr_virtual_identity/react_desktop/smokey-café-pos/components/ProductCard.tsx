import React from 'react';
import { motion } from 'framer-motion';
import { Plus } from 'lucide-react';
import { Product } from '../types';
import { ANIMATION_SPRING } from '../constants';

interface ProductCardProps {
  product: Product;
  onAdd: (product: Product) => void;
}

const ProductCard: React.FC<ProductCardProps> = ({ product, onAdd }) => {
  return (
    <motion.div
      layout
      initial={{ opacity: 0, scale: 0.8 }}
      animate={{ opacity: 1, scale: 1 }}
      exit={{ opacity: 0, scale: 0.8 }}
      whileHover={{ 
        y: -5, 
        scale: 1.02,
        boxShadow: "0px 10px 20px rgba(0,0,0,0.05)"
      }}
      whileTap={{ scale: 0.95 }}
      transition={ANIMATION_SPRING}
      onClick={() => onAdd(product)}
      className="bg-white rounded-[2rem] p-4 flex flex-col gap-4 cursor-pointer relative group border border-transparent hover:border-purple-100 overflow-hidden"
    >
      <div className="relative w-full aspect-[4/3] rounded-2xl overflow-hidden bg-gray-50">
         {/* Decorative blob for background */}
         <div className="absolute top-[-50%] left-[-50%] w-[200%] h-[200%] bg-purple-50 rounded-full opacity-50 group-hover:scale-110 transition-transform duration-500" />
         
        <img 
          src={product.image} 
          alt={product.name} 
          className="w-full h-full object-cover relative z-10 mix-blend-multiply opacity-90 group-hover:opacity-100 transition-opacity"
        />
        
        {/* Floating Add Icon */}
        <motion.div 
          className="absolute bottom-2 right-2 w-8 h-8 bg-white rounded-full flex items-center justify-center shadow-md text-purple-600 z-20"
          initial={{ scale: 0 }}
          whileHover={{ scale: 1.2, rotate: 90 }}
          animate={{ scale: 1 }}
        >
          <Plus size={18} strokeWidth={3} />
        </motion.div>
      </div>

      <div className="flex flex-col gap-1">
        <h3 className="font-semibold text-gray-800 text-lg leading-tight">{product.name}</h3>
        <p className="text-purple-600 font-bold text-md">RM {product.price.toFixed(2)}</p>
      </div>
    </motion.div>
  );
};

export default ProductCard;
