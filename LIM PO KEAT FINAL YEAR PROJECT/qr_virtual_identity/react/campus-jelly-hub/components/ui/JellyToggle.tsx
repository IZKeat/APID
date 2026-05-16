import React from 'react';
import { motion } from 'framer-motion';

interface JellyToggleProps {
  isOn: boolean;
  onToggle: () => void;
}

export const JellyToggle: React.FC<JellyToggleProps> = ({ isOn, onToggle }) => {
  return (
    <div 
      onClick={onToggle}
      className={`
        w-14 h-8 flex items-center rounded-full p-1 cursor-pointer transition-colors duration-300
        ${isOn ? 'bg-[#6750A4]' : 'bg-[#E7E0EC] border border-[#79747E]'}
      `}
    >
      <motion.div
        layout
        transition={{
          type: "spring",
          stiffness: 500,
          damping: 30
        }}
        className={`
          w-6 h-6 rounded-full shadow-md
          ${isOn ? 'bg-white' : 'bg-[#79747E]'}
        `}
        animate={{
            x: isOn ? 24 : 0,
            scale: isOn ? 1.2 : 0.8 // Breathing effect
        }}
        whileTap={{ width: 34 }} // Squish/Stretch effect on tap
      />
    </div>
  );
};