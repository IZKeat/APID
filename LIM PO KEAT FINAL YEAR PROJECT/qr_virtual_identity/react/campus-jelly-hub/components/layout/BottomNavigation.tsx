import React from 'react';
import { NavItem } from '../../types';
import { motion } from 'framer-motion';

interface BottomNavigationProps {
  items: NavItem[];
  activeTab: string;
  onTabChange: (id: string) => void;
}

export const BottomNavigation: React.FC<BottomNavigationProps> = ({ items, activeTab, onTabChange }) => {
  return (
    <div className="fixed bottom-0 left-0 right-0 bg-white/90 backdrop-blur-lg border-t border-gray-100 pb-safe pt-2 px-4 h-[88px] flex justify-around items-start z-50">
      {items.map((item) => {
        const isActive = activeTab === item.id;
        
        return (
          <button
            key={item.id}
            onClick={() => onTabChange(item.id)}
            className="relative flex flex-col items-center justify-center w-20 group"
          >
            {/* Active Indicator Pill */}
            {isActive && (
              <motion.div
                layoutId="nav-pill"
                className="absolute top-0 w-16 h-8 bg-[#E8DEF8] rounded-full"
                transition={{ type: "spring", stiffness: 500, damping: 30 }}
              />
            )}

            {/* Icon Container */}
            <div className={`relative z-10 flex items-center justify-center h-8 w-16 mb-1`}>
              <motion.div
                animate={isActive ? { scale: 1.1 } : { scale: 1 }}
                whileTap={{ scale: 0.9 }}
              >
                <item.icon 
                  size={24} 
                  strokeWidth={isActive ? 2.5 : 2}
                  className={`transition-colors duration-200 ${isActive ? 'text-[#1D192B]' : 'text-[#49454F]'}`} 
                />
              </motion.div>
            </div>

            {/* Label */}
            <span className={`text-xs font-semibold tracking-wide transition-all duration-200 ${isActive ? 'text-[#1D192B]' : 'text-[#49454F]'}`}>
              {item.label}
            </span>
          </button>
        );
      })}
    </div>
  );
};