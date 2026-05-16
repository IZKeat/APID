import React from 'react';
import { QrCode, User, Bell, Bus, BookOpen, HelpCircle, ArrowRight, Wallet } from 'lucide-react';
import { JellyCard } from '../components/ui/JellyCard';
import { motion, Variants } from 'framer-motion';

// Quick utility items for horizontal scroll
const QUICK_TOOLS = [
  { id: 1, label: 'Shuttle', icon: Bus, color: 'bg-orange-100 text-orange-800' },
  { id: 2, label: 'Library', icon: BookOpen, color: 'bg-blue-100 text-blue-800' },
  { id: 3, label: 'Support', icon: HelpCircle, color: 'bg-teal-100 text-teal-800' },
  { id: 4, label: 'Top Up', icon: Wallet, color: 'bg-green-100 text-green-800' },
];

const containerVariants: Variants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1,
      delayChildren: 0.1
    }
  }
};

const itemVariants: Variants = {
  hidden: { opacity: 0, y: 20 },
  visible: { 
    opacity: 1, 
    y: 0,
    transition: { type: "spring", stiffness: 300, damping: 24 }
  }
};

interface FunctionsViewProps {
    onOpenDigitalId: () => void;
}

export const FunctionsView: React.FC<FunctionsViewProps> = ({ onOpenDigitalId }) => {
  return (
    <div className="pb-32">
      <motion.div 
        variants={containerVariants}
        initial="hidden"
        animate="visible"
        className="px-6 pt-2 space-y-8"
      >
        
        {/* Section: Priority Access (Bento Grid) */}
        <div className="space-y-4">
            <motion.div variants={itemVariants} className="flex justify-between items-baseline">
                <h2 className="text-lg font-bold text-[#1D192B]">Priority Access</h2>
            </motion.div>

            <div className="grid grid-cols-2 gap-4 h-[400px]">
                {/* Left Column: Big QR Card */}
                <motion.div variants={itemVariants} className="h-full">
                    <JellyCard 
                        title="Digital ID" 
                        subtitle="Tap to Scan" 
                        icon={QrCode} 
                        colorClass="bg-[#EADDFF] text-[#21005D]" // M3 Surface Container High
                        className="h-full justify-between border-none"
                        onClick={onOpenDigitalId}
                    >
                        <div className="mt-auto flex justify-center py-6">
                            <div className="bg-white p-3 rounded-2xl shadow-sm rotate-3 group-hover:rotate-0 transition-transform duration-500">
                                <QrCode size={90} className="text-[#21005D] opacity-90" />
                            </div>
                        </div>
                    </JellyCard>
                </motion.div>

                {/* Right Column: Stacked Cards */}
                <div className="flex flex-col gap-4 h-full">
                    {/* Profile Card */}
                    <motion.div variants={itemVariants} className="flex-1">
                        <JellyCard 
                            title="Profile" 
                            subtitle="Identity Hub" 
                            icon={User} 
                            colorClass="bg-[#FFD8E4] text-[#31111D]" 
                            className="h-full border-none"
                            onClick={() => console.log('Profile Clicked')}
                        />
                    </motion.div>

                    {/* Notification Card - Redesigned as an Inbox preview */}
                    <motion.div variants={itemVariants} className="flex-1">
                        <JellyCard 
                            title="Inbox" 
                            colorClass="bg-[#F2F0F4] text-[#1D192B]"
                            icon={Bell}
                            className="h-full border-none"
                            onClick={() => console.log('Notifications Clicked')}
                        >
                            <div className="mt-3 flex items-start gap-3 bg-white p-3 rounded-xl shadow-sm">
                                <div className="min-w-[8px] h-[8px] mt-1.5 rounded-full bg-[#B3261E] animate-pulse" />
                                <div>
                                    <p className="text-xs font-bold leading-tight">Exam Schedule</p>
                                    <p className="text-[10px] text-gray-500 leading-tight mt-0.5">Final timetable released...</p>
                                </div>
                            </div>
                        </JellyCard>
                    </motion.div>
                </div>
            </div>
        </div>

        {/* Section: Quick Utilities (Horizontal Scroll) */}
        <div className="space-y-4">
             <motion.div variants={itemVariants} className="flex justify-between items-center">
                <h2 className="text-lg font-bold text-[#1D192B]">Quick Utilities</h2>
                <button className="text-xs font-bold text-[#6750A4] hover:bg-[#E8DEF8] px-2 py-1 rounded-lg transition-colors">See All</button>
            </motion.div>

            <motion.div 
                variants={itemVariants}
                className="flex gap-4 overflow-x-auto no-scrollbar pb-4 -mx-6 px-6 snap-x"
            >
                {QUICK_TOOLS.map((tool) => (
                    <motion.button
                        key={tool.id}
                        whileTap={{ scale: 0.9 }}
                        whileHover={{ y: -5 }}
                        className="flex flex-col items-center gap-2 min-w-[80px] snap-start"
                    >
                        <div className={`w-16 h-16 rounded-[24px] ${tool.color} flex items-center justify-center shadow-sm border border-white/50`}>
                            <tool.icon size={24} />
                        </div>
                        <span className="text-xs font-semibold text-[#49454F]">{tool.label}</span>
                    </motion.button>
                ))}
            </motion.div>
        </div>

        {/* Section: Feature Banner */}
        <motion.div variants={itemVariants} className="pt-2">
            <div className="bg-[#1D192B] rounded-[28px] p-6 text-[#F3EDF7] relative overflow-hidden group cursor-pointer">
                <div className="absolute top-0 right-0 w-32 h-32 bg-[#6750A4] rounded-full blur-[40px] translate-x-10 -translate-y-10" />
                
                <div className="relative z-10 flex justify-between items-center">
                    <div>
                        <h3 className="text-lg font-bold mb-1">Student Council Vote</h3>
                        <p className="text-sm opacity-70 mb-3">Voting closes in 24 hours</p>
                        <div className="inline-flex items-center gap-2 text-xs font-bold bg-[#4F378B] py-2 px-4 rounded-full">
                            Vote Now <ArrowRight size={12} />
                        </div>
                    </div>
                </div>
            </div>
        </motion.div>

      </motion.div>
    </div>
  );
};