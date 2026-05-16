import React, { useState } from 'react';
import { motion, Variants } from 'framer-motion';
import { Mail, Lock, Eye, EyeOff, GraduationCap, ArrowRight } from 'lucide-react';
import { JellyInput } from '../components/ui/JellyInput';

interface LoginViewProps {
  onLogin: () => void;
}

export const LoginView: React.FC<LoginViewProps> = ({ onLogin }) => {
  const [showPassword, setShowPassword] = useState(false);
  const [isChecked, setIsChecked] = useState(false);

  // Staggered animation for form elements
  const containerVariants: Variants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.1,
        delayChildren: 0.2
      }
    },
    exit: { opacity: 0, y: -20, transition: { duration: 0.3 } }
  };

  const itemVariants: Variants = {
    hidden: { opacity: 0, y: 20 },
    visible: { 
      opacity: 1, 
      y: 0,
      transition: { type: "spring", stiffness: 300, damping: 24 }
    }
  };

  return (
    <div className="min-h-screen flex flex-col items-center justify-center p-6 relative overflow-hidden">
      
      {/* Background Decor - Breathing Blob */}
      <motion.div 
        animate={{ 
            scale: [1, 1.2, 1],
            rotate: [0, 90, 0],
            opacity: [0.3, 0.5, 0.3]
        }}
        transition={{ duration: 10, repeat: Infinity, ease: "easeInOut" }}
        className="absolute top-[-10%] right-[-20%] w-[500px] h-[500px] bg-gradient-to-br from-[#E8DEF8] to-[#D0BCFF] rounded-full blur-[80px] z-0 pointer-events-none"
      />

      <motion.div
        variants={containerVariants}
        initial="hidden"
        animate="visible"
        exit="exit"
        className="w-full max-w-md z-10 flex flex-col gap-8"
      >
        {/* Hero Section - 3D Logo */}
        <motion.div variants={itemVariants} className="flex flex-col items-center mb-4">
            <motion.div
                whileHover={{ scale: 1.1, rotate: 10 }}
                whileTap={{ scale: 0.9, rotate: -10 }}
                className="w-28 h-28 bg-[#6750A4] rounded-[36px] flex items-center justify-center shadow-xl shadow-[#6750A4]/30 mb-6 relative group cursor-pointer"
            >
                <div className="absolute inset-0 bg-white opacity-0 group-hover:opacity-20 rounded-[36px] transition-opacity" />
                <GraduationCap size={64} className="text-white drop-shadow-md" />
                {/* Shine effect */}
                <div className="absolute top-4 right-4 w-4 h-4 bg-white/30 rounded-full blur-[2px]" />
            </motion.div>

            <h1 className="text-4xl font-extrabold text-[#1D192B] tracking-tight text-center">
              Welcome Back
            </h1>
            <p className="text-[#49454F] mt-2 font-medium text-center">
              Sign in to access your campus hub
            </p>
        </motion.div>

        {/* Form Section */}
        <div className="space-y-5">
            <motion.div variants={itemVariants}>
                <JellyInput 
                    icon={Mail} 
                    label="Student Email" 
                    placeholder="tp0XXXXX@mail.apu.edu.my" 
                    defaultValue="Tp072581@mail.apu.edu.my"
                />
            </motion.div>

            <motion.div variants={itemVariants}>
                <JellyInput 
                    icon={Lock} 
                    label="Password" 
                    type={showPassword ? "text" : "password"} 
                    placeholder="••••••" 
                    defaultValue="password123"
                    rightIcon={
                        <button onClick={() => setShowPassword(!showPassword)} tabIndex={-1}>
                            {showPassword ? <EyeOff size={20} /> : <Eye size={20} />}
                        </button>
                    }
                />
            </motion.div>

            <motion.div variants={itemVariants} className="flex items-center justify-between px-2">
                <label className="flex items-center gap-3 cursor-pointer group">
                    <div className="relative">
                        <input 
                            type="checkbox" 
                            className="peer sr-only" 
                            checked={isChecked}
                            onChange={() => setIsChecked(!isChecked)}
                        />
                        <motion.div 
                            animate={isChecked ? { scale: 1.1, backgroundColor: "#6750A4" } : { scale: 1, backgroundColor: "#E6E0E9" }}
                            className="w-6 h-6 rounded-lg border-2 border-transparent peer-focus:ring-2 peer-focus:ring-[#6750A4]/30 transition-colors"
                        />
                        {isChecked && (
                             <motion.div 
                                initial={{ scale: 0 }} 
                                animate={{ scale: 1 }} 
                                className="absolute inset-0 flex items-center justify-center text-white pointer-events-none"
                             >
                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="4" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg>
                             </motion.div>
                        )}
                    </div>
                    <span className="text-sm font-semibold text-[#49454F] group-hover:text-[#1D192B] transition-colors">Remember Me</span>
                </label>
                
                <button className="text-sm font-bold text-[#6750A4] hover:underline">Forgot?</button>
            </motion.div>
        </div>

        {/* Action Buttons */}
        <div className="space-y-4 pt-2">
            <motion.button
                variants={itemVariants}
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.95 }}
                onClick={onLogin}
                className="w-full bg-[#6750A4] text-white h-14 rounded-[28px] font-bold text-lg shadow-lg shadow-[#6750A4]/30 flex items-center justify-center gap-2 relative overflow-hidden group"
            >
                <span className="relative z-10">Login</span>
                <ArrowRight size={20} className="relative z-10 group-hover:translate-x-1 transition-transform" />
                
                {/* Liquid Highlight on Hover */}
                <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent -translate-x-full group-hover:translate-x-full transition-transform duration-700 ease-in-out z-0" />
            </motion.button>

            <motion.div variants={itemVariants} className="relative flex items-center py-2">
                <div className="flex-grow border-t border-gray-200"></div>
                <span className="flex-shrink-0 mx-4 text-xs font-bold text-gray-400 uppercase tracking-widest">Or</span>
                <div className="flex-grow border-t border-gray-200"></div>
            </motion.div>

            <motion.button
                variants={itemVariants}
                whileHover={{ scale: 1.02, backgroundColor: "#F3EDF7" }}
                whileTap={{ scale: 0.95 }}
                onClick={onLogin}
                className="w-full bg-transparent border-2 border-[#CAC4D0] text-[#1D192B] h-14 rounded-[28px] font-bold text-base transition-colors"
            >
                Continue as Guest
            </motion.button>
        </div>
      </motion.div>
    </div>
  );
};