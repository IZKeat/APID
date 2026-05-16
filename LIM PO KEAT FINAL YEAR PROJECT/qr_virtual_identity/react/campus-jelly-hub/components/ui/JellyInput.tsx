import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { LucideIcon } from 'lucide-react';

interface JellyInputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  icon: LucideIcon;
  label: string;
  rightIcon?: React.ReactNode;
}

export const JellyInput: React.FC<JellyInputProps> = ({ icon: Icon, label, rightIcon, className, ...props }) => {
  const [isFocused, setIsFocused] = useState(false);

  return (
    <div className={`space-y-1.5 ${className}`}>
      <label className="text-xs font-bold text-[#6750A4] ml-4 uppercase tracking-wider opacity-80">
        {label}
      </label>
      <motion.div
        animate={isFocused ? { scale: 1.02, backgroundColor: '#FFFFFF' } : { scale: 1, backgroundColor: '#F3EDF7' }}
        transition={{ type: "spring", stiffness: 400, damping: 25 }}
        className={`
          relative flex items-center 
          rounded-[24px] 
          border-2 
          ${isFocused ? 'border-[#6750A4] shadow-md shadow-[#6750A4]/10' : 'border-transparent'}
          transition-colors duration-200
        `}
      >
        <div className="pl-5 text-[#6750A4]">
          <Icon size={20} />
        </div>
        <input
          {...props}
          onFocus={(e) => {
            setIsFocused(true);
            props.onFocus?.(e);
          }}
          onBlur={(e) => {
            setIsFocused(false);
            props.onBlur?.(e);
          }}
          className="w-full bg-transparent px-4 py-4 text-[#1D192B] placeholder:text-[#1D192B]/40 font-medium focus:outline-none"
        />
        {rightIcon && (
          <div className="pr-5 text-gray-400 hover:text-[#6750A4] transition-colors cursor-pointer">
            {rightIcon}
          </div>
        )}
      </motion.div>
    </div>
  );
};
