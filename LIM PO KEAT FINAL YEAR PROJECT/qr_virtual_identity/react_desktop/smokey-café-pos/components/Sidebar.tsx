
import React from 'react';
import { LogOut, LucideIcon } from 'lucide-react';
import { motion } from 'framer-motion';
import { ANIMATION_SPRING } from '../constants';
import { ViewType } from '../types';

export interface MenuItem {
  icon: LucideIcon;
  label: string;
  view: ViewType;
}

interface SidebarProps {
  activeView: ViewType;
  onNavigate: (view: ViewType) => void;
  onLogout: () => void;
  menuItems: MenuItem[];
}

const Sidebar: React.FC<SidebarProps> = ({ activeView, onNavigate, onLogout, menuItems }) => {
  const LogoIcon = menuItems[0]?.icon;

  return (
    <motion.aside 
      initial={{ x: -50, opacity: 0 }}
      animate={{ x: 0, opacity: 1 }}
      className="w-24 bg-white flex flex-col items-center py-8 h-full shadow-sm z-20"
    >
      <div className="mb-10">
        <motion.div 
          whileHover={{ rotate: 15, scale: 1.1 }}
          transition={ANIMATION_SPRING}
          className="w-12 h-12 bg-purple-100 rounded-2xl flex items-center justify-center text-purple-600 shadow-sm"
        >
          {/* Use the icon of the first menu item as the logo placeholder if available, or default */}
          {LogoIcon && <LogoIcon size={24} />}
        </motion.div>
      </div>

      <nav className="flex-1 flex flex-col gap-6 w-full px-4">
        {menuItems.map((item) => {
          const isActive = activeView === item.view;
          return (
            <motion.button
              key={item.view}
              onClick={() => onNavigate(item.view)}
              whileHover={{ scale: 1.1, backgroundColor: isActive ? '#f3e8ff' : '#f9fafb' }}
              whileTap={{ scale: 0.85 }} // Jelly squash effect
              transition={ANIMATION_SPRING}
              className={`w-full aspect-square rounded-2xl flex flex-col items-center justify-center gap-1 transition-colors relative overflow-hidden ${
                isActive 
                  ? 'bg-purple-100 text-purple-700 shadow-inner' 
                  : 'text-gray-400 hover:text-purple-600'
              }`}
            >
              {/* Active indicator dot */}
              {isActive && (
                <motion.div 
                  layoutId="active-dot"
                  className="absolute top-2 right-2 w-1.5 h-1.5 bg-purple-500 rounded-full" 
                />
              )}
              <item.icon size={22} strokeWidth={isActive ? 2.5 : 2} />
              <span className="text-[10px] font-medium">{item.label}</span>
            </motion.button>
          );
        })}
      </nav>

      <motion.button
        onClick={onLogout}
        whileHover={{ scale: 1.1, backgroundColor: '#fee2e2', rotate: 5 }}
        whileTap={{ scale: 0.9 }}
        transition={ANIMATION_SPRING}
        className="w-12 h-12 rounded-2xl flex items-center justify-center text-red-400 hover:text-red-600 mt-auto hover:shadow-md"
      >
        <LogOut size={22} />
      </motion.button>
    </motion.aside>
  );
};

export default Sidebar;
