
import React from 'react';
import { motion } from 'framer-motion';
import { ScanLine, Shield, Lightbulb, User, Smartphone, ChevronDown } from 'lucide-react';
import { ANIMATION_SPRING } from '../constants';

const containerVariants = {
  hidden: { opacity: 0 },
  show: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1,
      delayChildren: 0.2
    }
  }
};

const itemVariants = {
  hidden: { y: 20, opacity: 0, scale: 0.95 },
  show: { 
    y: 0, 
    opacity: 1, 
    scale: 1,
    transition: ANIMATION_SPRING
  }
};

const Attendance = () => {
  return (
    <motion.div 
      variants={containerVariants}
      initial="hidden"
      animate="show"
      exit={{ opacity: 0, y: -20 }}
      className="flex-1 overflow-y-auto px-6 py-8 md:px-12 md:py-12 no-scrollbar flex flex-col items-center max-w-7xl mx-auto w-full"
    >
      
      {/* Event Selector Top Card */}
      <motion.div 
        variants={itemVariants} 
        whileHover={{ scale: 1.02 }}
        whileTap={{ scale: 0.98 }}
        transition={ANIMATION_SPRING}
        className="bg-white px-8 py-6 rounded-[2rem] shadow-sm mb-12 flex items-center gap-6 cursor-pointer border border-transparent hover:border-purple-100"
      >
        <div className="flex-1">
            <h2 className="text-gray-900 font-bold text-lg">Select Event for Attendance</h2>
        </div>
        <div className="text-gray-400">
            <ChevronDown size={24} />
        </div>
      </motion.div>

      {/* Header Section */}
      <motion.div variants={itemVariants} className="text-center flex flex-col items-center gap-6 mb-12">
        <motion.div 
          className="relative"
          animate={{ y: [0, -10, 0] }}
          transition={{ duration: 4, repeat: Infinity, ease: "easeInOut" }}
        >
          <div className="absolute inset-0 bg-indigo-400 blur-3xl opacity-20 rounded-full scale-150" />
          <motion.div 
             whileHover={{ scale: 1.1, rotate: 180 }}
             transition={{ duration: 0.5, type: "spring" }}
             className="w-28 h-28 bg-gradient-to-tr from-indigo-500 to-purple-600 rounded-[2rem] flex items-center justify-center text-white shadow-xl shadow-indigo-200 relative z-10"
          >
            <ScanLine size={48} strokeWidth={2} />
          </motion.div>
        </motion.div>

        <div>
          <h1 className="text-4xl md:text-5xl font-extrabold text-gray-900 tracking-tight mb-2">Mobile QR Scanner</h1>
          <p className="text-gray-500 text-lg font-medium">Trigger your mobile device to open the QR scanner</p>
        </div>

        {/* User Badge */}
        <motion.div 
          variants={itemVariants}
          className="bg-blue-50 text-blue-800 px-6 py-3 rounded-full font-medium flex items-center gap-3 border border-blue-100 shadow-sm"
        >
          <User size={18} className="text-blue-600" />
          <span>Logged in as: <span className="font-bold">sp007@apu.edu.my</span></span>
        </motion.div>
      </motion.div>

      {/* Attendance Mode Trigger */}
      <div className="w-full max-w-2xl flex flex-col gap-6 mb-12">
        <h2 className="text-xl font-bold text-gray-800 text-center mb-2">Attendance Taking</h2>
        
        <motion.button
          variants={itemVariants}
          whileHover={{ scale: 1.02, y: -2 }}
          whileTap={{ scale: 0.95 }}
          transition={ANIMATION_SPRING}
          className="group w-full bg-[#FF6B35] hover:bg-[#F25C24] text-white rounded-[2rem] p-6 flex items-center justify-center gap-4 shadow-lg shadow-orange-200 transition-all border-b-4 border-[#D94F1F] active:border-b-0 active:translate-y-1 relative overflow-hidden"
        >
            <div className="absolute inset-0 bg-white/10 opacity-0 group-hover:opacity-100 transition-opacity" />
            <Shield size={32} strokeWidth={2.5} />
            <span className="text-2xl font-bold">Start Attendance Mode</span>
        </motion.button>
      </div>

      {/* Instructions Card */}
      <motion.div 
        variants={itemVariants}
        className="w-full max-w-2xl bg-[#FFFBEB] rounded-[2.5rem] p-8 border border-[#FEF3C7] shadow-inner"
      >
        <div className="flex items-center gap-3 mb-6">
          <div className="p-2 bg-[#FEF3C7] rounded-xl text-[#D97706]">
            <Lightbulb size={24} strokeWidth={2.5} />
          </div>
          <h3 className="text-xl font-bold text-[#92400E]">How to Use</h3>
        </div>

        <div className="space-y-6">
          {[
            "Open your mobile app (Android/iOS)",
            "Login with the SAME merchant account",
            "Mobile will show QR Scanner page",
            "Click \"Trigger\" button above",
            "Scanner activates automatically! 📱"
          ].map((step, index) => (
            <motion.div 
              key={index}
              initial={{ x: -20, opacity: 0 }}
              animate={{ x: 0, opacity: 1 }}
              transition={{ delay: 0.5 + (index * 0.1), ...ANIMATION_SPRING }}
              className="flex items-center gap-4 group"
            >
              <div className="w-8 h-8 rounded-full bg-[#6366F1] text-white font-bold flex items-center justify-center shrink-0 shadow-md group-hover:scale-110 transition-transform">
                {index + 1}
              </div>
              <p className="text-gray-700 font-medium text-lg flex items-center gap-2">
                {step.replace("📱", "")}
                {step.includes("📱") && <Smartphone size={18} className="text-gray-500"/>}
              </p>
            </motion.div>
          ))}
        </div>
      </motion.div>

    </motion.div>
  );
};

export default Attendance;
