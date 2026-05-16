import React from 'react';
import { motion } from 'framer-motion';

export const TopAppBar: React.FC = () => {
  const today = new Date();
  const dateStr = today.toLocaleDateString('en-US', { weekday: 'long', day: 'numeric', month: 'short' });

  return (
    <motion.header 
      initial={{ opacity: 0, y: -20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ type: "spring", stiffness: 300, damping: 30 }}
      className="bg-[#FDF7FF]/80 backdrop-blur-md pt-12 pb-4 px-6 sticky top-0 z-30 border-b border-transparent"
    >
      <div className="flex justify-between items-end">
        <div>
            <motion.p 
                initial={{ opacity: 0, x: -10 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.2 }}
                className="text-xs font-bold tracking-widest text-[#6750A4] uppercase mb-1"
            >
                {dateStr}
            </motion.p>
            <h1 className="text-xl font-bold text-[#1D192B] leading-none">Campus Hub</h1>
        </div>
        
        <motion.div 
            whileTap={{ scale: 0.9 }}
            className="relative"
        >
             <div className="w-10 h-10 rounded-full bg-gradient-to-tr from-[#6750A4] to-[#D0BCFF] p-[2px] shadow-md cursor-pointer">
                 <div className="w-full h-full rounded-full bg-white flex items-center justify-center overflow-hidden">
                    <img src="https://api.dicebear.com/9.x/micah/svg?seed=Felix" alt="User" className="w-full h-full object-cover" />
                 </div>
             </div>
             {/* Online Status Indicator */}
             <div className="absolute bottom-0 right-0 w-3 h-3 bg-green-400 border-2 border-white rounded-full"></div>
        </motion.div>
      </div>
    </motion.header>
  );
};