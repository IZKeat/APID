import React, { useState } from 'react';
import { motion, Variants } from 'framer-motion';
import { ArrowLeft, Bell, Moon, Lock, Shield, ChevronRight, Smartphone, Mail } from 'lucide-react';
import { JellyToggle } from '../components/ui/JellyToggle';
import { JellyCard } from '../components/ui/JellyCard';

interface SettingsViewProps {
  onBack: () => void;
}

const containerVariants: Variants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { staggerChildren: 0.05, delayChildren: 0.1 }
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

export const SettingsView: React.FC<SettingsViewProps> = ({ onBack }) => {
  const [notifications, setNotifications] = useState({
    push: true,
    email: false,
    updates: true,
  });
  
  const [darkMode, setDarkMode] = useState(false);

  const SettingRow: React.FC<{ icon: any, label: string, subLabel?: string, control: React.ReactNode }> = ({ icon: Icon, label, subLabel, control }) => (
    <div className="flex items-center justify-between py-3">
        <div className="flex items-center gap-4">
            <div className="w-10 h-10 rounded-xl bg-[#F3EDF7] flex items-center justify-center text-[#49454F]">
                <Icon size={20} />
            </div>
            <div>
                <p className="font-bold text-[#1D192B] leading-tight">{label}</p>
                {subLabel && <p className="text-xs text-gray-500 mt-0.5">{subLabel}</p>}
            </div>
        </div>
        {control}
    </div>
  );

  return (
    <div className="min-h-screen bg-[#FDF7FF] text-[#1D192B] flex flex-col z-50 relative">
      
      {/* Header */}
      <div className="px-6 pt-12 pb-4 flex items-center gap-4 bg-white/80 backdrop-blur-md sticky top-0 z-40 border-b border-gray-100">
        <motion.button 
          whileTap={{ scale: 0.9 }}
          onClick={onBack}
          className="p-2 -ml-2 rounded-full hover:bg-gray-100"
        >
          <ArrowLeft size={24} />
        </motion.button>
        <h1 className="text-xl font-bold">Settings</h1>
      </div>

      <motion.div 
        variants={containerVariants}
        initial="hidden"
        animate="visible"
        className="p-6 space-y-6 flex-1 overflow-y-auto"
      >
        
        {/* Section: Notifications */}
        <motion.div variants={itemVariants}>
            <h2 className="text-sm font-bold text-[#6750A4] uppercase tracking-wider mb-3 ml-1">Notifications</h2>
            <JellyCard 
                title="" 
                colorClass="bg-white" 
                className="!p-4 border border-gray-100 shadow-sm"
            >
                <div className="space-y-2 divide-y divide-gray-50">
                    <SettingRow 
                        icon={Smartphone} 
                        label="Push Notifications" 
                        subLabel="Events & Security alerts"
                        control={
                            <JellyToggle 
                                isOn={notifications.push} 
                                onToggle={() => setNotifications({...notifications, push: !notifications.push})} 
                            />
                        } 
                    />
                    <SettingRow 
                        icon={Mail} 
                        label="Email Updates" 
                        subLabel="Newsletter & Promotions"
                        control={
                            <JellyToggle 
                                isOn={notifications.email} 
                                onToggle={() => setNotifications({...notifications, email: !notifications.email})} 
                            />
                        } 
                    />
                </div>
            </JellyCard>
        </motion.div>

        {/* Section: Appearance */}
        <motion.div variants={itemVariants}>
            <h2 className="text-sm font-bold text-[#6750A4] uppercase tracking-wider mb-3 ml-1">Appearance</h2>
            <JellyCard 
                title="" 
                colorClass="bg-white" 
                className="!p-4 border border-gray-100 shadow-sm"
            >
                <SettingRow 
                    icon={Moon} 
                    label="Dark Mode" 
                    subLabel="Reduce eye strain"
                    control={
                        <JellyToggle 
                            isOn={darkMode} 
                            onToggle={() => setDarkMode(!darkMode)} 
                        />
                    } 
                />
            </JellyCard>
        </motion.div>

        {/* Section: Security */}
        <motion.div variants={itemVariants}>
            <h2 className="text-sm font-bold text-[#6750A4] uppercase tracking-wider mb-3 ml-1">Security</h2>
            <JellyCard 
                title="" 
                colorClass="bg-white" 
                className="!p-4 border border-gray-100 shadow-sm"
            >
                <div className="space-y-2 divide-y divide-gray-50">
                    <motion.div 
                        whileTap={{ scale: 0.98 }}
                        className="flex items-center justify-between py-3 cursor-pointer"
                    >
                        <div className="flex items-center gap-4">
                            <div className="w-10 h-10 rounded-xl bg-[#E8DEF8] flex items-center justify-center text-[#1D192B]">
                                <Lock size={20} />
                            </div>
                            <span className="font-bold text-[#1D192B]">Change Password</span>
                        </div>
                        <ChevronRight size={20} className="text-gray-400" />
                    </motion.div>
                    
                    <motion.div 
                        whileTap={{ scale: 0.98 }}
                        className="flex items-center justify-between py-3 cursor-pointer"
                    >
                        <div className="flex items-center gap-4">
                            <div className="w-10 h-10 rounded-xl bg-[#E8DEF8] flex items-center justify-center text-[#1D192B]">
                                <Shield size={20} />
                            </div>
                            <span className="font-bold text-[#1D192B]">Privacy Policy</span>
                        </div>
                        <ChevronRight size={20} className="text-gray-400" />
                    </motion.div>
                </div>
            </JellyCard>
        </motion.div>

        {/* Account ID */}
        <motion.div variants={itemVariants} className="pt-4 text-center">
             <p className="text-xs font-bold text-gray-400">Account ID: 9942-XJ-22</p>
        </motion.div>

      </motion.div>
    </div>
  );
};