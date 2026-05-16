import React, { useState } from 'react';
import { motion, AnimatePresence, Variants } from 'framer-motion';
import { ArrowLeft, Search, ChevronDown, MessageCircle, Mail } from 'lucide-react';
import { JellyCard } from '../components/ui/JellyCard';

interface HelpViewProps {
  onBack: () => void;
}

const FAQS = [
    { q: "How do I access my digital ID?", a: "Go to the Functions tab and tap on the large 'Digital ID' card. You can refresh the code every 60 seconds." },
    { q: "How do I register for events?", a: "Navigate to the Events tab, select an event you like, and tap 'View Registration'. Confirm your spot instantly." },
    { q: "Can I cancel a booking?", a: "Yes, go to 'My Booking' in the Events tab, select the ticket, and tap 'Cancel Ticket'. Please do this 24h in advance." },
];

const containerVariants: Variants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: { staggerChildren: 0.1, delayChildren: 0.1 }
    }
};

const itemVariants: Variants = {
    hidden: { opacity: 0, y: 10 },
    visible: { opacity: 1, y: 0 }
};

export const HelpView: React.FC<HelpViewProps> = ({ onBack }) => {
  const [openFaq, setOpenFaq] = useState<number | null>(0);

  return (
    <div className="min-h-screen bg-[#FDF7FF] text-[#1D192B] flex flex-col z-50 relative">
      
      {/* Header */}
      <div className="px-6 pt-12 pb-4 bg-[#FDF7FF] sticky top-0 z-40">
        <div className="flex items-center gap-4 mb-4">
            <motion.button 
                whileTap={{ scale: 0.9 }}
                onClick={onBack}
                className="p-2 -ml-2 rounded-full hover:bg-gray-100"
            >
                <ArrowLeft size={24} />
            </motion.button>
            <h1 className="text-xl font-bold">Help & Support</h1>
        </div>

        {/* Search Bar */}
        <div className="relative">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" size={20} />
            <input 
                type="text" 
                placeholder="Search for help..." 
                className="w-full bg-white h-12 rounded-2xl pl-12 pr-4 font-medium text-sm shadow-sm border border-gray-100 focus:outline-none focus:border-[#6750A4] transition-colors"
            />
        </div>
      </div>

      <motion.div 
        variants={containerVariants}
        initial="hidden"
        animate="visible"
        className="px-6 pb-12 overflow-y-auto"
      >
        
        {/* Contact Options */}
        <div className="grid grid-cols-2 gap-4 mb-8">
            <motion.div variants={itemVariants}>
                <JellyCard 
                    title="" 
                    colorClass="bg-[#EADDFF] text-[#21005D]" 
                    className="!p-4 items-center justify-center text-center gap-2 h-32"
                >
                    <div className="w-10 h-10 bg-white/50 rounded-full flex items-center justify-center mb-1">
                        <MessageCircle size={20} />
                    </div>
                    <span className="font-bold text-sm">Live Chat</span>
                    <span className="text-[10px] opacity-70">Wait time: ~2m</span>
                </JellyCard>
            </motion.div>
            <motion.div variants={itemVariants}>
                <JellyCard 
                    title="" 
                    colorClass="bg-[#FFD8E4] text-[#31111D]" 
                    className="!p-4 items-center justify-center text-center gap-2 h-32"
                >
                    <div className="w-10 h-10 bg-white/50 rounded-full flex items-center justify-center mb-1">
                        <Mail size={20} />
                    </div>
                    <span className="font-bold text-sm">Email Us</span>
                    <span className="text-[10px] opacity-70">Reply in 24h</span>
                </JellyCard>
            </motion.div>
        </div>

        {/* FAQ Section */}
        <motion.h2 variants={itemVariants} className="text-lg font-bold mb-4">Frequently Asked</motion.h2>
        
        <motion.div variants={itemVariants} className="space-y-3">
            {FAQS.map((faq, index) => (
                <JellyCard 
                    key={index}
                    title="" 
                    colorClass="bg-white" 
                    className="!p-0 border border-gray-100 overflow-hidden"
                    onClick={() => setOpenFaq(openFaq === index ? null : index)}
                >
                    <div className="p-4 flex items-center justify-between font-bold text-sm">
                        {faq.q}
                        <motion.div 
                            animate={{ rotate: openFaq === index ? 180 : 0 }}
                            className="text-[#6750A4]"
                        >
                            <ChevronDown size={20} />
                        </motion.div>
                    </div>
                    <AnimatePresence>
                        {openFaq === index && (
                            <motion.div
                                initial={{ height: 0, opacity: 0 }}
                                animate={{ height: 'auto', opacity: 1 }}
                                exit={{ height: 0, opacity: 0 }}
                                className="overflow-hidden"
                            >
                                <div className="px-4 pb-4 text-xs text-gray-500 leading-relaxed border-t border-gray-50 pt-2">
                                    {faq.a}
                                </div>
                            </motion.div>
                        )}
                    </AnimatePresence>
                </JellyCard>
            ))}
        </motion.div>

      </motion.div>
    </div>
  );
};