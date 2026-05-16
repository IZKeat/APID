
import React from 'react';
import { motion } from 'framer-motion';
import { Store, ShieldCheck, QrCode, ClipboardList, Wallet, Clock, History, Library as LibraryIcon, School, CalendarCheck } from 'lucide-react';
import { ANIMATION_SPRING } from '../constants';

interface ProfileProps {
  userEmail?: string;
}

const containerVariants = {
  hidden: { opacity: 0 },
  show: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1,
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
    transition: {
      type: "spring" as const,
      stiffness: 300,
      damping: 20
    }
  }
};

// Data configuration for different user profiles
const getUserProfile = (email: string) => {
  if (email && email.startsWith('sp002')) {
    return {
      name: 'Library Counter',
      id: 'SP002',
      type: 'LIBRARY',
      typeColor: 'bg-indigo-100 text-indigo-700',
      description: 'Book borrowing and return checkpoint',
      icon: LibraryIcon,
      iconBg: 'bg-indigo-50 text-indigo-500',
      stats: [
        { label: 'Total Scans', value: '6', icon: QrCode, color: 'bg-orange-100 text-orange-600' },
        { label: 'Total Interactions', value: '3', icon: ClipboardList, color: 'bg-blue-100 text-blue-600' },
        { label: 'Last Active', value: '14m ago', icon: Clock, color: 'bg-slate-100 text-slate-600' }
      ]
    };
  }

  if (email && email.startsWith('sp006')) {
    return {
      name: 'Lecture Hall B Attendance',
      id: 'SP006',
      type: 'ACCESS',
      typeColor: 'bg-indigo-100 text-indigo-700',
      description: 'Lecture attendance check-in point',
      icon: School,
      iconBg: 'bg-indigo-50 text-indigo-500',
      stats: [
        { label: 'Total Scans', value: '22', icon: QrCode, color: 'bg-orange-100 text-orange-600' },
        { label: 'Total Interactions', value: '21', icon: ClipboardList, color: 'bg-blue-100 text-blue-600' },
        { label: 'Last Active', value: '16m ago', icon: Clock, color: 'bg-slate-100 text-slate-600' }
      ]
    };
  }

  if (email && email.startsWith('sp007')) {
    return {
      name: 'Event Check-In Counter',
      id: 'SP007',
      type: 'EVENT',
      typeColor: 'bg-purple-100 text-purple-700',
      description: 'Event ticket verification and check-in point',
      icon: Store, // Keeping Store icon as per screenshot, or could be CalendarCheck
      iconBg: 'bg-purple-50 text-purple-500',
      stats: [
        { label: 'Total Scans', value: '0', icon: QrCode, color: 'bg-orange-100 text-orange-600' },
        { label: 'Total Interactions', value: '0', icon: ClipboardList, color: 'bg-blue-100 text-blue-600' },
        { label: 'Last Active', value: '0m ago', icon: Clock, color: 'bg-slate-100 text-slate-600' }
      ]
    };
  }
  
  // Default to POS (sp001)
  return {
    name: 'Smokey Café',
    id: 'SP001',
    type: 'COMMERCE',
    typeColor: 'bg-purple-100 text-purple-700',
    description: 'Campus cafeteria serving coffee, sandwiches, and snacks. Specializes in quick bites for students on the go.',
    icon: Store,
    iconBg: 'bg-purple-50 text-purple-500',
    stats: [
      { label: 'Total Scans', value: '54', icon: QrCode, color: 'bg-orange-100 text-orange-600' },
      { label: 'Total Interactions', value: '51', icon: ClipboardList, color: 'bg-blue-100 text-blue-600' },
      { label: 'Total Revenue', value: 'RM 195.90', icon: Wallet, color: 'bg-emerald-100 text-emerald-600' },
      { label: 'Last Active', value: '21m ago', icon: Clock, color: 'bg-slate-100 text-slate-600' }
    ]
  };
};

const Profile: React.FC<ProfileProps> = ({ userEmail = '' }) => {
  const profile = getUserProfile(userEmail);
  const Icon = profile.icon;

  return (
    <motion.div 
      variants={containerVariants}
      initial="hidden"
      animate="show"
      exit={{ opacity: 0, y: -20, scale: 0.95 }}
      className="flex-1 overflow-y-auto px-8 py-8 no-scrollbar"
    >
      <div className="max-w-6xl mx-auto flex flex-col gap-6">
        
        {/* Header Card */}
        <motion.div 
          variants={itemVariants}
          whileHover={{ scale: 1.01 }}
          transition={ANIMATION_SPRING}
          className="bg-white rounded-[2.5rem] p-8 shadow-sm flex flex-col md:flex-row items-center md:items-start gap-8 relative overflow-hidden group border border-transparent hover:border-indigo-50/50"
        >
           {/* Decorative Background Blob */}
          <div className="absolute top-0 right-0 w-64 h-64 bg-gray-50 rounded-full translate-x-1/2 -translate-y-1/2 opacity-50 group-hover:scale-125 transition-transform duration-700 ease-out" />

          <motion.div 
            whileHover={{ scale: 1.1, rotate: -5 }}
            whileTap={{ scale: 0.9 }}
            transition={ANIMATION_SPRING}
            className={`w-32 h-32 ${profile.iconBg} rounded-[2rem] flex items-center justify-center shrink-0 shadow-inner relative z-10`}
          >
            <Icon size={56} strokeWidth={1.5} />
          </motion.div>
          
          <div className="flex-1 flex flex-col items-center md:items-start text-center md:text-left relative z-10 pt-2">
            <h1 className="text-4xl font-extrabold text-gray-900 mb-3 tracking-tight">{profile.name}</h1>
            
            <div className="flex flex-wrap gap-3 justify-center md:justify-start">
              <span className="px-4 py-1.5 bg-indigo-50 text-indigo-600 rounded-full text-sm font-bold tracking-wide uppercase border border-indigo-100">
                ID: {profile.id}
              </span>
              <span className={`px-4 py-1.5 ${profile.typeColor} rounded-full text-sm font-bold tracking-wide uppercase border border-white/50 shadow-sm`}>
                {profile.type}
              </span>
              <div className="px-4 py-1.5 bg-emerald-100 text-emerald-700 rounded-full text-sm font-bold flex items-center gap-1.5 shadow-sm border border-emerald-200/50">
                <ShieldCheck size={14} strokeWidth={3} />
                <span>Verified</span>
              </div>
            </div>
          </div>
        </motion.div>

        {/* Stats Grid */}
        <motion.div 
          variants={itemVariants}
          className={`grid grid-cols-1 md:grid-cols-2 lg:grid-cols-${profile.stats.length} gap-4`}
        >
          {profile.stats.map((stat, idx) => (
            <motion.div
              key={idx}
              whileHover={{ scale: 1.03, y: -4 }}
              whileTap={{ scale: 0.97 }}
              transition={ANIMATION_SPRING}
              className="bg-white p-6 rounded-[2rem] shadow-sm hover:shadow-xl hover:shadow-gray-200/50 transition-all cursor-default border border-transparent hover:border-gray-50"
            >
              <div className={`w-14 h-14 ${stat.color} rounded-2xl flex items-center justify-center mb-4`}>
                <stat.icon size={28} strokeWidth={2} />
              </div>
              <p className="text-gray-400 text-sm font-bold tracking-wide mb-1 uppercase">{stat.label}</p>
              <h3 className="text-3xl font-extrabold text-gray-900">{stat.value}</h3>
            </motion.div>
          ))}
        </motion.div>

        {/* Description / Bio Card */}
        <motion.div 
            variants={itemVariants}
            whileHover={{ scale: 1.01 }}
            className="bg-white rounded-[2rem] p-8 shadow-sm border border-transparent hover:border-gray-100 transition-colors"
        >
            <p className="text-lg md:text-xl text-gray-700 font-medium leading-relaxed">
                {profile.description}
            </p>
        </motion.div>

        {/* Recent Activity Section */}
        <motion.div variants={itemVariants} className="flex flex-col gap-4">
          <h2 className="text-xl font-bold text-gray-800 ml-2 flex items-center gap-2">
             <History size={20} className="text-gray-400"/>
             Recent Activity
          </h2>
          
          <motion.div 
            className="bg-white rounded-[2.5rem] p-12 flex flex-col items-center justify-center text-center shadow-sm min-h-[250px] relative overflow-hidden"
            whileHover={{ scale: 1.005 }}
            transition={ANIMATION_SPRING}
          >
             {/* Subtle background pattern */}
             <div className="absolute inset-0 opacity-[0.03]" 
                  style={{ backgroundImage: 'radial-gradient(#6366f1 1px, transparent 1px)', backgroundSize: '20px 20px' }} 
             />

            <motion.div 
              animate={{ 
                y: [0, -8, 0],
                rotate: [0, 5, -5, 0]
              }}
              transition={{ 
                duration: 6, 
                repeat: Infinity,
                ease: "easeInOut" 
              }}
              className="w-24 h-24 bg-indigo-50 rounded-[2rem] flex items-center justify-center text-indigo-300 mb-6 shadow-inner"
            >
              <History size={48} strokeWidth={1.5} />
            </motion.div>
            <h3 className="text-gray-900 font-bold text-xl mb-2">No recent activities available</h3>
            <p className="text-gray-400 max-w-sm mx-auto font-medium leading-relaxed">
              Your recent transactions and system logs will appear here once you start using the system.
            </p>
          </motion.div>
        </motion.div>

      </div>
    </motion.div>
  );
};

export default Profile;
