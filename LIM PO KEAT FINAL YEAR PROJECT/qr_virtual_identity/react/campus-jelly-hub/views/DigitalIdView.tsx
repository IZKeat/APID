import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence, useMotionValue, useSpring, useTransform } from 'framer-motion';
import { ArrowLeft, RefreshCw, ShieldCheck, Copy, Check, Sparkles } from 'lucide-react';
import { JellyCard } from '../components/ui/JellyCard';

interface DigitalIdViewProps {
  onBack: () => void;
}

export const DigitalIdView: React.FC<DigitalIdViewProps> = ({ onBack }) => {
  const [timeLeft, setTimeLeft] = useState(59);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [copied, setCopied] = useState(false);

  // Mouse parallax for background
  const mouseX = useMotionValue(0);
  const mouseY = useMotionValue(0);

  // Countdown timer logic
  useEffect(() => {
    const timer = setInterval(() => {
      setTimeLeft((prev) => {
        if (prev <= 1) return 60; // Auto reset
        return prev - 1;
      });
    }, 1000);
    
    const handleMouseMove = (e: MouseEvent) => {
        const { clientX, clientY } = e;
        const centerX = window.innerWidth / 2;
        const centerY = window.innerHeight / 2;
        mouseX.set((clientX - centerX) / 50);
        mouseY.set((clientY - centerY) / 50);
    };

    window.addEventListener('mousemove', handleMouseMove);
    return () => {
        clearInterval(timer);
        window.removeEventListener('mousemove', handleMouseMove);
    };
  }, [mouseX, mouseY]);

  const handleRefresh = () => {
    setIsRefreshing(true);
    setTimeout(() => {
      setTimeLeft(60);
      setIsRefreshing(false);
    }, 1200); // Slightly longer for the glitch effect
  };

  const handleCopyId = () => {
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="min-h-screen bg-[#1D192B] text-[#E6E0E9] flex flex-col relative overflow-hidden">
      
      {/* Interactive Background Blobs */}
      <motion.div 
        style={{ x: mouseX, y: mouseY }}
        className="absolute inset-0 z-0 pointer-events-none"
      >
        <motion.div 
            animate={{ scale: [1, 1.2, 1], rotate: [0, 45, 0], opacity: [0.2, 0.4, 0.2] }}
            transition={{ duration: 15, repeat: Infinity, ease: "linear" }}
            className="absolute top-[-20%] left-[-20%] w-[600px] h-[600px] bg-[#6750A4] rounded-full blur-[120px] opacity-30"
        />
        <motion.div 
            animate={{ scale: [1, 1.1, 1], rotate: [0, -30, 0], opacity: [0.1, 0.3, 0.1] }}
            transition={{ duration: 10, repeat: Infinity, ease: "easeInOut" }}
            className="absolute bottom-[-10%] right-[-10%] w-[500px] h-[500px] bg-[#D0BCFF] rounded-full blur-[100px] opacity-20"
        />
      </motion.div>

      {/* Header */}
      <div className="relative z-10 px-6 pt-12 pb-4 flex items-center justify-between">
        <motion.button 
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
          whileTap={{ scale: 0.9 }}
          onClick={onBack}
          className="p-3 bg-white/10 backdrop-blur-md rounded-full text-white hover:bg-white/20 transition-colors border border-white/10"
        >
          <ArrowLeft size={24} />
        </motion.button>
        
        <motion.h1 
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-xl font-bold tracking-tight text-white/90"
        >
          My Digital ID
        </motion.h1>
        
        <div className="w-12" />
      </div>

      {/* Main Content */}
      <div className="flex-1 flex flex-col items-center justify-center p-6 relative z-10 gap-8">
        
        {/* The Jelly ID Card */}
        <motion.div
          initial={{ scale: 0.8, opacity: 0, rotateX: 20 }}
          animate={{ scale: 1, opacity: 1, rotateX: 0 }}
          transition={{ type: "spring", stiffness: 200, damping: 20 }}
          className="w-full max-w-sm relative"
        >
           {/* Glow behind card */}
           <div className="absolute inset-4 bg-[#6750A4] blur-[40px] opacity-40 -z-10" />

          <JellyCard 
            title="" 
            colorClass="bg-white text-[#1D192B]" 
            className="!rounded-[32px] overflow-hidden !border-none shadow-2xl shadow-purple-900/40 relative"
          >
             {/* Holographic Overlay Effect */}
            <div className="absolute inset-0 bg-gradient-to-tr from-transparent via-white/10 to-transparent opacity-0 hover:opacity-100 transition-opacity duration-500 pointer-events-none z-20 mix-blend-overlay" />
            
            <div className="p-2 flex flex-col items-center relative z-10">
                {/* Secure Header */}
                <div className="w-full flex justify-between items-center px-4 py-3 border-b border-gray-100 mb-6">
                    <div className="flex items-center gap-2 text-[#6750A4]">
                        <ShieldCheck size={16} />
                        <span className="text-xs font-bold uppercase tracking-widest">Secure Identity</span>
                    </div>
                    <div className="flex items-center gap-1.5 bg-green-50 px-2 py-1 rounded-full border border-green-100">
                        <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
                        <span className="text-[10px] font-bold text-green-700">Live</span>
                    </div>
                </div>

                {/* QR Container */}
                <div className="relative w-64 h-64 bg-[#F5F5F5] rounded-[28px] p-4 mb-6 group cursor-pointer overflow-hidden border border-black/5 shadow-inner">
                    {/* The QR Code with Glitch Effect */}
                    <AnimatePresence mode='wait'>
                        {!isRefreshing ? (
                            <motion.div
                                key="qr-code"
                                initial={{ opacity: 0, filter: "blur(10px)" }}
                                animate={{ opacity: 1, filter: "blur(0px)" }}
                                exit={{ opacity: 0, scale: 1.1, filter: "blur(5px)" }}
                                className="w-full h-full bg-white rounded-2xl flex items-center justify-center overflow-hidden relative"
                            >
                                <img 
                                    src={`https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=TP072581-${Math.floor(timeLeft/10)}&color=21005D`} 
                                    alt="QR Code" 
                                    className="w-full h-full object-contain mix-blend-multiply opacity-90"
                                />
                                
                                {/* Corner Accents */}
                                <div className="absolute top-0 left-0 w-8 h-8 border-t-4 border-l-4 border-[#6750A4] rounded-tl-xl opacity-20" />
                                <div className="absolute top-0 right-0 w-8 h-8 border-t-4 border-r-4 border-[#6750A4] rounded-tr-xl opacity-20" />
                                <div className="absolute bottom-0 left-0 w-8 h-8 border-b-4 border-l-4 border-[#6750A4] rounded-bl-xl opacity-20" />
                                <div className="absolute bottom-0 right-0 w-8 h-8 border-b-4 border-r-4 border-[#6750A4] rounded-br-xl opacity-20" />
                            </motion.div>
                        ) : (
                            <motion.div
                                key="glitch"
                                className="w-full h-full flex items-center justify-center bg-black/5"
                            >
                                <motion.div 
                                    animate={{ rotate: 360 }}
                                    transition={{ duration: 1, ease: "linear" }}
                                    className="w-12 h-12 border-4 border-[#6750A4] border-t-transparent rounded-full" 
                                />
                            </motion.div>
                        )}
                    </AnimatePresence>

                    {/* Scanner Beam Animation - Only when not refreshing */}
                    {!isRefreshing && (
                        <motion.div 
                            animate={{ top: ["-10%", "110%", "-10%"] }}
                            transition={{ duration: 4, repeat: Infinity, ease: "linear" }}
                            className="absolute left-0 right-0 h-12 bg-gradient-to-b from-[#6750A4]/0 via-[#6750A4]/20 to-[#6750A4]/0 z-20 pointer-events-none backdrop-blur-[1px]"
                        >
                            <div className="w-full h-[1px] bg-[#6750A4]/60 absolute top-1/2" />
                        </motion.div>
                    )}
                </div>

                {/* Student Info */}
                <div className="text-center mb-6">
                    <div className="flex items-center justify-center gap-2 mb-1">
                        <h2 className="text-2xl font-black text-[#1D192B]">Felix Lee</h2>
                        <Sparkles size={16} className="text-yellow-500 animate-pulse" />
                    </div>
                    <button 
                        onClick={handleCopyId}
                        className="group relative inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-gray-50 hover:bg-gray-100 transition-colors text-sm font-bold text-gray-500 overflow-hidden"
                    >
                        <span className="relative z-10">TP072581</span>
                        <div className="relative z-10">
                             {copied ? <Check size={14} className="text-green-600" /> : <Copy size={14} className="group-hover:text-[#6750A4] transition-colors" />}
                        </div>
                        {copied && <motion.div layoutId="copy-bg" className="absolute inset-0 bg-green-100" />}
                    </button>
                </div>

                {/* Countdown Indicator */}
                <div className="w-full bg-[#F3EDF7] rounded-2xl p-4 flex items-center justify-between shadow-inner">
                    <div className="flex flex-col">
                        <span className="text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-0.5">Code expires in</span>
                        <span className="text-xl font-black text-[#6750A4] tabular-nums tracking-tight">00:{timeLeft.toString().padStart(2, '0')}</span>
                    </div>
                    {/* Visual Progress Ring */}
                    <div className="relative w-12 h-12 flex items-center justify-center bg-white rounded-full shadow-sm">
                        <svg className="w-full h-full -rotate-90 p-1">
                            <circle cx="20" cy="20" r="16" fill="none" stroke="#E6E0E9" strokeWidth="4" />
                            <motion.circle 
                                cx="20" cy="20" r="16" fill="none" stroke="#6750A4" strokeWidth="4" 
                                strokeLinecap="round"
                                strokeDasharray="100"
                                animate={{ strokeDashoffset: 100 - (timeLeft / 60) * 100 }}
                                transition={{ duration: 1, ease: "linear" }}
                            />
                        </svg>
                        <div className="absolute text-[10px] font-bold text-[#1D192B]">
                            {timeLeft}s
                        </div>
                    </div>
                </div>

            </div>
          </JellyCard>
        </motion.div>

        {/* Action Button - Liquid Jelly Style */}
        <motion.button
            whileHover={{ scale: 1.05, y: -2 }}
            whileTap={{ scale: 0.95, y: 2 }}
            onClick={handleRefresh}
            className="group relative px-8 py-4 bg-[#D0BCFF] text-[#381E72] rounded-[24px] font-bold text-lg shadow-[0_10px_20px_rgba(49,20,94,0.3)] flex items-center gap-3 overflow-hidden"
        >
            <motion.div
                animate={isRefreshing ? { rotate: 360 } : {}}
                transition={{ duration: 0.8, ease: "linear", repeat: isRefreshing ? Infinity : 0 }}
            >
                <RefreshCw size={22} strokeWidth={3} />
            </motion.div>
            <span>Refresh Code</span>
            
            {/* Liquid highlight effect */}
            <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/40 to-transparent -translate-x-[200%] group-hover:translate-x-[200%] transition-transform duration-700 ease-in-out skew-x-12" />
        </motion.button>
      </div>
    </div>
  );
};