import React, { useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ShoppingCart, QrCode, Minus, Plus, Trash2 } from 'lucide-react';
import { CartItem } from '../types';
import { ANIMATION_SPRING, ANIMATION_BOUNCE } from '../constants';

interface CartProps {
  items: CartItem[];
  onUpdateQuantity: (uuid: string, delta: number) => void;
  onRemove: (uuid: string) => void;
  onClear: () => void;
}

const Cart: React.FC<CartProps> = ({ items, onUpdateQuantity, onRemove, onClear }) => {
  const total = useMemo(() => items.reduce((acc, item) => acc + (item.price * item.quantity), 0), [items]);

  return (
    <div className="flex flex-col h-full bg-white w-full rounded-l-[2.5rem] shadow-xl overflow-hidden relative border-l border-gray-100">
      
      {/* Header */}
      <div className="p-8 pb-4 flex items-center justify-between">
        <h2 className="text-2xl font-bold text-gray-800">Current Order</h2>
        <motion.button 
            whileHover={{ scale: 1.1, rotate: 10 }}
            whileTap={{ scale: 0.9 }}
            onClick={onClear}
            className="text-gray-400 hover:text-red-500 p-2"
        >
            <Trash2 size={20} />
        </motion.button>
      </div>

      {/* Cart Items List */}
      <div className="flex-1 overflow-y-auto px-6 py-2 no-scrollbar">
        <AnimatePresence mode='popLayout'>
          {items.length === 0 ? (
            <motion.div 
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              className="h-full flex flex-col items-center justify-center text-gray-300 gap-4"
            >
              <ShoppingCart size={64} strokeWidth={1.5} />
              <p className="text-lg font-medium">Cart is empty</p>
            </motion.div>
          ) : (
            <div className="flex flex-col gap-4">
              {items.map((item) => (
                <motion.div
                  key={item.uuid}
                  layout
                  initial={{ opacity: 0, x: 50, scale: 0.9 }}
                  animate={{ opacity: 1, x: 0, scale: 1 }}
                  exit={{ opacity: 0, x: -50, scale: 0.5 }}
                  transition={ANIMATION_SPRING}
                  className="bg-gray-50 p-3 rounded-2xl flex items-center gap-3 group hover:bg-purple-50 transition-colors"
                >
                  <img src={item.image} alt={item.name} className="w-14 h-14 rounded-xl object-cover" />
                  
                  <div className="flex-1 min-w-0">
                    <h4 className="font-semibold text-gray-800 text-sm truncate">{item.name}</h4>
                    <p className="text-purple-600 font-bold text-sm">RM {(item.price * item.quantity).toFixed(2)}</p>
                  </div>

                  <div className="flex items-center gap-2 bg-white rounded-xl p-1 shadow-sm">
                    <motion.button 
                        whileTap={{ scale: 0.8 }}
                        onClick={() => onUpdateQuantity(item.uuid, -1)}
                        className="w-7 h-7 flex items-center justify-center bg-gray-100 rounded-lg hover:bg-gray-200 text-gray-600"
                    >
                        <Minus size={14} />
                    </motion.button>
                    <span className="w-4 text-center text-sm font-semibold">{item.quantity}</span>
                    <motion.button 
                         whileTap={{ scale: 0.8 }}
                         onClick={() => onUpdateQuantity(item.uuid, 1)}
                         className="w-7 h-7 flex items-center justify-center bg-purple-100 rounded-lg hover:bg-purple-200 text-purple-700"
                    >
                        <Plus size={14} />
                    </motion.button>
                  </div>
                </motion.div>
              ))}
            </div>
          )}
        </AnimatePresence>
      </div>

      {/* Footer / Total */}
      <div className="p-6 bg-white border-t border-gray-100">
        <div className="flex justify-between items-end mb-6">
          <span className="text-gray-400 font-medium">Total</span>
          <motion.span 
            key={total}
            initial={{ scale: 1.2, color: '#9333ea' }}
            animate={{ scale: 1, color: '#111827' }}
            className="text-3xl font-bold text-gray-900"
          >
            RM {total.toFixed(2)}
          </motion.span>
        </div>

        <motion.button
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.95 }}
          transition={ANIMATION_BOUNCE}
          className="w-full py-4 bg-gray-900 text-white rounded-2xl font-semibold text-lg flex items-center justify-center gap-3 shadow-lg shadow-gray-200 hover:bg-purple-900 hover:shadow-purple-200 transition-all"
        >
          <QrCode size={24} />
          Scan User QR
        </motion.button>
      </div>
    </div>
  );
};

export default Cart;
