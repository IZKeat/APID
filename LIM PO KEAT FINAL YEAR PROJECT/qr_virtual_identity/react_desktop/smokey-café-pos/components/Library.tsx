
import React from 'react';
import { motion } from 'framer-motion';
import { ScanLine, BookOpen, RotateCcw, Lightbulb, User } from 'lucide-react';
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

const Library = () => {
  return (
    <motion.div 
      variants={containerVariants}
      initial="hidden"
      animate="show"
      exit={{ opacity: 0, y: -20 }}
      className="flex-1 overflow-y-auto px-6 py-8 md:px-12 md:py-12 no-scrollbar flex flex-col items-center max-w-7xl mx-auto w-full"
    >
      
      {/* Header Section */}
      <motion.div variants={itemVariants} className="text-center flex flex-col items-center gap-6 mb-12">
        <motion.div 
          className="relative"
          animate={{ y: [0, -10, 0] }}
          transition={{ duration: 4, repeat: Infinity, ease: "easeInOut" }}
        >
          <div className="absolute inset-0 bg-blue-400 blur-3xl opacity-20 rounded-full scale-150" />
          <motion.div 
             whileHover={{ scale: 1.1, rotate: 180 }}
             transition={{ duration: 0.5, type: "spring" }}
             className="w-28 h-28 bg-gradient-to-tr from-blue-500 to-indigo-600 rounded-[2rem] flex items-center justify-center text-white shadow-xl shadow-blue-200 relative z-10"
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
          <span>Logged in as: <span className="font-bold">sp002@apu.edu.my</span></span>
        </motion.div>
      </motion.div>

      {/* Operations Buttons */}
      <div className="w-full max-w-2xl flex flex-col gap-6 mb-12">
        <h2 className="text-xl font-bold text-gray-800 text-center mb-2">Library Operations</h2>
        
        {/* Borrow Button */}
        <motion.button
          variants={itemVariants}
          whileHover={{ scale: 1.02, y: -2 }}
          whileTap={{ scale: 0.95 }}
          transition={ANIMATION_SPRING}
          className="group w-full bg-emerald-500 hover:bg-emerald-600 text-white rounded-[2rem] p-6 flex items-center gap-6 shadow-lg shadow-emerald-200 transition-all border-b-4 border-emerald-700 active:border-b-0 active:translate-y-1"
        >
          <div className="w-16 h-16 bg-white/20 rounded-2xl flex items-center justify-center group-hover:rotate-12 transition-transform duration-300">
            <BookOpen size={32} />
          </div>
          <div className="flex-1 text-left">
            <h3 className="text-2xl font-bold">Borrow Mode</h3>
            <p className="text-emerald-100 font-medium">Student + Book</p>
          </div>
          <div className="w-10 h-10 rounded-full bg-white/20 flex items-center justify-center">
            <ScanLine size={20} />
          </div>
        </motion.button>

        {/* Return Button */}
        <motion.button
          variants={itemVariants}
          whileHover={{ scale: 1.02, y: -2 }}
          whileTap={{ scale: 0.95 }}
          transition={ANIMATION_SPRING}
          className="group w-full bg-sky-500 hover:bg-sky-600 text-white rounded-[2rem] p-6 flex items-center gap-6 shadow-lg shadow-sky-200 transition-all border-b-4 border-sky-700 active:border-b-0 active:translate-y-1"
        >
          <div className="w-16 h-16 bg-white/20 rounded-2xl flex items-center justify-center group-hover:-rotate-12 transition-transform duration-300">
            <RotateCcw size={32} />
          </div>
          <div className="flex-1 text-left">
            <h3 className="text-2xl font-bold">Return Mode</h3>
            <p className="text-sky-100 font-medium">Book Only</p>
          </div>
          <div className="w-10 h-10 rounded-full bg-white/20 flex items-center justify-center">
            <ScanLine size={20} />
          </div>
        </motion.button>
      </div>

      {/* Instructions Card */}
      <motion.div 
        variants={itemVariants}
        className="w-full max-w-2xl bg-amber-50 rounded-[2.5rem] p-8 border border-amber-100 shadow-inner"
      >
        <div className="flex items-center gap-3 mb-6">
          <div className="p-2 bg-amber-100 rounded-xl text-amber-600">
            <Lightbulb size={24} strokeWidth={2.5} />
          </div>
          <h3 className="text-xl font-bold text-amber-900">How to Use</h3>
        </div>

        <div className="space-y-6">
          {[
            "Open your mobile app (Android/iOS)",
            "Login with the SAME merchant account",
            "Mobile will show QR Scanner page",
            "Click \"Trigger\" button above"
          ].map((step, index) => (
            <motion.div 
              key={index}
              initial={{ x: -20, opacity: 0 }}
              animate={{ x: 0, opacity: 1 }}
              transition={{ delay: 0.5 + (index * 0.1), ...ANIMATION_SPRING }}
              className="flex items-center gap-4 group"
            >
              <div className="w-8 h-8 rounded-full bg-indigo-500 text-white font-bold flex items-center justify-center shrink-0 shadow-md group-hover:scale-110 transition-transform">
                {index + 1}
              </div>
              <p className="text-gray-700 font-medium text-lg">{step}</p>
            </motion.div>
          ))}
        </div>
      </motion.div>

    </motion.div>
  );
};

export default Library;
