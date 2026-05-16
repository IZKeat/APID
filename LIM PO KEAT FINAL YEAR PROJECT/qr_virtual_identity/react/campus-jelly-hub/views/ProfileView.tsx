import React from 'react';
import { User, Settings, HelpCircle, LogOut, Award, Ticket, Zap, ChevronRight } from 'lucide-react';
import { JellyCard } from '../components/ui/JellyCard';
import { motion, Variants } from 'framer-motion';

const containerVariants: Variants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1,
      delayChildren: 0.05
    }
  }
};

const itemVariants: Variants = {
  hidden: { opacity: 0, y: 20, scale: 0.95 },
  visible: { 
    opacity: 1, 
    y: 0, 
    scale: 1,
    transition: { type: "spring", stiffness: 300, damping: 24 }
  }
};

const StatItem: React.FC<{ icon: any, label: string, value: string, color: string, delay: number }> = ({ icon: Icon, label, value, color, delay }) => (
  <motion.div 
    initial={{ opacity: 0, scale: 0.5 }}
    animate={{ opacity: 1, scale: 1 }}
    transition={{ type: "spring", stiffness: 400, damping: 20, delay: delay }}
    whileTap={{ scale: 0.9 }}
    className="flex flex-col items-center justify-center bg-white p-3 rounded-2xl shadow-sm border border-gray-100 flex-1 min-w-[90px]"
  >
    <div className={`p-2 rounded-full ${color} bg-opacity-15 mb-2`}>
        <Icon size={20} className={color.replace('bg-', 'text-')} />
    </div>
    <span className="text-xl font-black text-[#1D192B] leading-none mb-1">{value}</span>
    <span className="text-[10px] font-bold text-gray-400 uppercase tracking-wider">{label}</span>
  </motion.div>
);

interface ProfileViewProps {
    onOpenSettings?: () => void;
    onOpenHelp?: () => void;
}

export const ProfileView: React.FC<ProfileViewProps> = ({ onOpenSettings, onOpenHelp }) => {
  return (
    <div className="pb-32 px-6 pt-2 min-h-screen">
      <motion.div 
        variants={containerVariants}
        initial="hidden"
        animate="visible"
        className="space-y-6"
      >
        
        {/* Identity Hub - Hero Card */}
        <motion.div variants={itemVariants}>
            <div className="bg-white rounded-[32px] p-6 shadow-sm border border-white/60 relative overflow-hidden text-center group">
                 {/* Decorative Blobs */}
                 <div className="absolute top-0 left-0 w-full h-32 bg-[#F3EDF7] rounded-b-[50%] scale-150 -translate-y-1/2 z-0" />
                 
                 <div className="relative z-10 flex flex-col items-center">
                     <motion.div 
                        whileTap={{ scale: 0.8, rotate: 15 }}
                        whileHover={{ scale: 1.1, rotate: -5 }}
                        transition={{ type: "spring", stiffness: 300, damping: 15 }}
                        className="w-28 h-28 rounded-full bg-white p-1.5 shadow-lg mb-4 cursor-pointer"
                     >
                        <div className="w-full h-full rounded-full bg-[#EADDFF] overflow-hidden relative">
                             <img 
                                src="https://api.dicebear.com/9.x/micah/svg?seed=Felix&backgroundColor=b6e3f4" 
                                alt="Profile" 
                                className="w-full h-full object-cover"
                             />
                        </div>
                     </motion.div>

                     <h2 className="text-2xl font-bold text-[#1D192B] mb-1">User Name</h2>
                     <p className="text-sm text-gray-500 font-medium mb-3">tp072581@mail.apu.edu.my</p>
                     
                     <div className="bg-[#E8DEF8] text-[#1D192B] px-4 py-1.5 rounded-full text-xs font-bold uppercase tracking-wide">
                        Student
                     </div>
                 </div>
            </div>
        </motion.div>

        {/* Gamification Stats Row */}
        <div className="flex justify-between gap-3">
            <StatItem icon={Ticket} label="Tickets" value="12" color="bg-blue-100 text-blue-600" delay={0.2} />
            <StatItem icon={Zap} label="Points" value="850" color="bg-yellow-100 text-yellow-600" delay={0.3} />
            <StatItem icon={Award} label="Badges" value="5" color="bg-purple-100 text-purple-600" delay={0.4} />
        </div>

        {/* Menu Section */}
        <div className="space-y-4">
            <h3 className="text-sm font-bold text-gray-500 uppercase tracking-widest pl-2">Preferences</h3>
            
            <motion.div variants={itemVariants}>
                <JellyCard 
                    title="Settings" 
                    subtitle="App preferences & notifications"
                    icon={Settings} 
                    colorClass="bg-white text-[#1D192B]" 
                    className="border border-gray-100"
                    onClick={onOpenSettings}
                />
            </motion.div>

            <motion.div variants={itemVariants}>
                <JellyCard 
                    title="Help & Support" 
                    subtitle="Get help and contact support"
                    icon={HelpCircle} 
                    colorClass="bg-white text-[#1D192B]" 
                    className="border border-gray-100"
                    onClick={onOpenHelp}
                />
            </motion.div>
        </div>

        {/* Danger Zone */}
        <motion.div variants={itemVariants} className="pt-4">
             <JellyCard 
                title=""
                colorClass="bg-[#F9DEDC] text-[#410E0B]"
                className="!p-0 border-none group"
                onClick={() => console.log('Sign Out')}
             >
                <div className="p-4 flex items-center justify-between">
                    <div className="flex items-center gap-4">
                        <div className="bg-white/50 p-2.5 rounded-xl">
                            <LogOut size={20} />
                        </div>
                        <span className="font-bold text-lg">Sign Out</span>
                    </div>
                    <ChevronRight size={20} className="opacity-50 group-hover:translate-x-1 transition-transform" />
                </div>
             </JellyCard>
        </motion.div>

        <div className="text-center py-6 text-[10px] text-gray-400 font-medium">
            Version 2.4.0 • Campus Jelly Hub
        </div>

      </motion.div>
    </div>
  );
};