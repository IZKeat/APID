
import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { GraduationCap, Mail, Lock, Eye, EyeOff, ArrowRight, QrCode, Check } from 'lucide-react';
import { ANIMATION_SPRING } from '../constants';

interface LoginProps {
  onLogin: (email: string) => void;
}

const Login: React.FC<LoginProps> = ({ onLogin }) => {
  const [showPassword, setShowPassword] = useState(false);
  const [rememberMe, setRememberMe] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [email, setEmail] = useState("sp007@apu.edu.my");

  // Staggered entrance animation variants
  const containerVariants = {
    hidden: { opacity: 0 },
    show: {
      opacity: 1,
      transition: {
        staggerChildren: 0.08,
        delayChildren: 0.1
      }
    }
  };

  const itemVariants = {
    hidden: { y: 30, opacity: 0, scale: 0.9 },
    show: { 
      y: 0, 
      opacity: 1, 
      scale: 1,
      transition: { type: "spring" as const, stiffness: 300, damping: 20 }
    }
  };

  const handleLoginSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    
    // Simulate API delay for feedback
    setTimeout(() => {
      setIsLoading(false);
      onLogin(email);
    }, 1500);
  };

  return (
    <div className="min-h-screen w-full bg-[#FAFAFA] flex items-center justify-center relative overflow-hidden font-sans text-gray-800">
      
      {/* Decorative Background Blob */}
      <motion.div 
        initial={{ scale: 0, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ duration: 1.5, ease: "easeOut" }}
        className="absolute -top-32 -right-32 w-[600px] h-[600px] bg-purple-100/50 rounded-full blur-3xl z-0 pointer-events-none" 
      />

      <motion.div 
        variants={containerVariants}
        initial="hidden"
        animate="show"
        className="w-full max-w-lg p-8 flex flex-col gap-8 relative z-10"
      >
        
        {/* Header Section */}
        <motion.div variants={itemVariants} className="flex flex-col items-center text-center gap-6">
          <motion.div 
            whileHover={{ rotate: 15, scale: 1.1 }}
            whileTap={{ scale: 0.9 }}
            transition={ANIMATION_SPRING}
            className="w-24 h-24 bg-[#6B46C1] rounded-[2rem] flex items-center justify-center text-white shadow-xl shadow-purple-200"
          >
            <GraduationCap size={48} strokeWidth={1.5} />
          </motion.div>
          
          <div className="space-y-2">
            <h1 className="text-4xl font-bold text-gray-900 tracking-tight">Welcome Back</h1>
            <p className="text-gray-500 font-medium">Sign in to access your campus hub</p>
          </div>
        </motion.div>

        {/* Login Form */}
        <form onSubmit={handleLoginSubmit} className="flex flex-col gap-6">
          
          {/* Email Input */}
          <motion.div variants={itemVariants} className="space-y-2">
            <label className="text-sm font-bold text-purple-900 ml-4 tracking-wide uppercase text-xs opacity-70">Student Email</label>
            <motion.div 
              className="relative group"
              whileTap={{ scale: 0.98 }}
            >
              <div className="absolute left-6 top-1/2 -translate-y-1/2 text-purple-400 group-focus-within:text-purple-600 transition-colors">
                <Mail size={20} />
              </div>
              <input 
                type="email" 
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full bg-[#F3E8FF] text-gray-900 placeholder-purple-300 rounded-full py-4 pl-16 pr-6 font-medium focus:outline-none focus:ring-4 focus:ring-purple-100 transition-all border-2 border-transparent focus:border-purple-200"
                placeholder="Enter your student email"
              />
            </motion.div>
          </motion.div>

          {/* Password Input */}
          <motion.div variants={itemVariants} className="space-y-2">
            <label className="text-sm font-bold text-purple-900 ml-4 tracking-wide uppercase text-xs opacity-70">Password</label>
            <motion.div 
              className="relative group"
              whileTap={{ scale: 0.98 }}
            >
              <div className="absolute left-6 top-1/2 -translate-y-1/2 text-purple-400 group-focus-within:text-purple-600 transition-colors">
                <Lock size={20} />
              </div>
              <input 
                type={showPassword ? "text" : "password"}
                defaultValue="password123"
                className="w-full bg-[#F3E8FF] text-gray-900 placeholder-purple-300 rounded-full py-4 pl-16 pr-14 font-medium focus:outline-none focus:ring-4 focus:ring-purple-100 transition-all border-2 border-transparent focus:border-purple-200"
                placeholder="Enter your password"
              />
              <button 
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-6 top-1/2 -translate-y-1/2 text-purple-400 hover:text-purple-600 transition-colors"
              >
                {showPassword ? <EyeOff size={20} /> : <Eye size={20} />}
              </button>
            </motion.div>
          </motion.div>

          {/* Options: Remember Me & Forgot Password */}
          <motion.div variants={itemVariants} className="flex items-center justify-between px-2">
            <motion.button
              type="button"
              onClick={() => setRememberMe(!rememberMe)}
              className="flex items-center gap-3 text-gray-500 hover:text-gray-700 transition-colors cursor-pointer group"
              whileTap={{ scale: 0.95 }}
            >
              <div className={`w-6 h-6 rounded-lg border-2 flex items-center justify-center transition-all ${
                rememberMe ? 'bg-[#6B46C1] border-[#6B46C1]' : 'border-gray-300 group-hover:border-[#6B46C1]'
              }`}>
                {rememberMe && <Check size={14} className="text-white" strokeWidth={3} />}
              </div>
              <span className="font-medium text-sm">Remember Me</span>
            </motion.button>
            
            <a href="#" className="text-sm font-bold text-[#6B46C1] hover:text-[#553C9A] hover:underline">
              Forgot?
            </a>
          </motion.div>

          {/* Login Button */}
          <motion.button
            variants={itemVariants}
            whileHover={{ scale: 1.03 }}
            whileTap={{ scale: 0.95 }}
            transition={ANIMATION_SPRING}
            disabled={isLoading}
            className="w-full bg-[#6B46C1] text-white rounded-full py-4 font-bold text-lg shadow-lg shadow-purple-200 hover:shadow-purple-300 flex items-center justify-center gap-3 relative overflow-hidden"
          >
            <AnimatePresence mode="wait">
              {isLoading ? (
                 <motion.div
                    key="loading"
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -10 }}
                    className="flex items-center gap-2"
                 >
                    <div className="w-5 h-5 border-3 border-white/30 border-t-white rounded-full animate-spin" />
                    <span>Signing in...</span>
                 </motion.div>
              ) : (
                <motion.div
                  key="idle"
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -10 }}
                  className="flex items-center gap-2"
                >
                  <span>Login</span>
                  <ArrowRight size={20} strokeWidth={3} />
                </motion.div>
              )}
            </AnimatePresence>
          </motion.button>

          {/* QR Code Login Button */}
          <motion.button
            type="button"
            variants={itemVariants}
            whileHover={{ scale: 1.03, backgroundColor: '#F3E8FF' }}
            whileTap={{ scale: 0.95 }}
            transition={ANIMATION_SPRING}
            className="w-full bg-white text-[#6B46C1] border-2 border-[#E9D8FD] rounded-full py-4 font-bold text-lg flex items-center justify-center gap-3 hover:border-[#6B46C1] transition-colors"
          >
            <QrCode size={20} />
            <span>Login with QR Code</span>
          </motion.button>

        </form>
      </motion.div>

      {/* Footer Illustration / Info */}
      <div className="absolute bottom-6 right-8 text-right opacity-30 pointer-events-none hidden md:block">
        <p className="text-6xl font-black text-gray-300">30</p>
        <p className="text-xl font-medium text-gray-400">Nov 2025</p>
      </div>

    </div>
  );
};

export default Login;
