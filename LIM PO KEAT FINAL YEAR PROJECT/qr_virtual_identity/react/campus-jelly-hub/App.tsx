import React, { useState } from 'react';
import { LayoutGrid, Calendar, UserCircle } from 'lucide-react';
import { NavItem, Event } from './types';
import { BottomNavigation } from './components/layout/BottomNavigation';
import { TopAppBar } from './components/layout/TopAppBar';
import { FunctionsView } from './views/FunctionsView';
import { EventsView } from './views/EventsView';
import { ProfileView } from './views/ProfileView';
import { LoginView } from './views/LoginView';
import { DigitalIdView } from './views/DigitalIdView';
import { EventDetailView } from './views/EventDetailView';
import { SettingsView } from './views/SettingsView';
import { HelpView } from './views/HelpView';
import { motion, AnimatePresence } from 'framer-motion';

const NAV_ITEMS: NavItem[] = [
  { id: 'functions', label: 'Functions', icon: LayoutGrid },
  { id: 'events', label: 'Events', icon: Calendar },
  { id: 'profile', label: 'Profile', icon: UserCircle },
];

const App: React.FC = () => {
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [activeTab, setActiveTab] = useState('functions');
  const [showDigitalId, setShowDigitalId] = useState(false);
  const [selectedEvent, setSelectedEvent] = useState<Event | null>(null);
  
  // New States for Profile Features
  const [showSettings, setShowSettings] = useState(false);
  const [showHelp, setShowHelp] = useState(false);

  const handleLogin = () => {
    setIsLoggedIn(true);
  };

  return (
    <div className="min-h-screen bg-transparent text-[#1D192B] font-sans overflow-hidden flex flex-col">
      <AnimatePresence mode="wait">
        {!isLoggedIn ? (
          <motion.div
            key="login"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0, scale: 0.95, filter: "blur(10px)" }}
            transition={{ duration: 0.4 }}
            className="h-full w-full"
          >
            <LoginView onLogin={handleLogin} />
          </motion.div>
        ) : (
          <motion.div
            key="main-app"
            initial={{ opacity: 0, y: 50 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ type: "spring", stiffness: 100, damping: 20, delay: 0.1 }}
            className="flex flex-col h-full relative"
          >
             {/* Main App Content */}
             <div className="flex flex-col h-full">
                <TopAppBar />

                <main className="flex-1 overflow-y-auto no-scrollbar relative z-10">
                  <AnimatePresence mode="wait">
                    {activeTab === 'functions' && (
                      <motion.div 
                        key="functions"
                        initial={{ opacity: 0, x: -20 }}
                        animate={{ opacity: 1, x: 0 }}
                        exit={{ opacity: 0, x: -20 }}
                        className="h-full"
                      >
                        <FunctionsView onOpenDigitalId={() => setShowDigitalId(true)} />
                      </motion.div>
                    )}
                    {activeTab === 'events' && (
                      <motion.div 
                        key="events"
                        initial={{ opacity: 0, x: 20 }}
                        animate={{ opacity: 1, x: 0 }}
                        exit={{ opacity: 0, x: 20 }}
                      >
                        <EventsView 
                            onOpenDigitalId={() => setShowDigitalId(true)}
                            onEventSelect={(event) => setSelectedEvent(event)} 
                        />
                      </motion.div>
                    )}
                    {activeTab === 'profile' && (
                      <motion.div 
                        key="profile"
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        exit={{ opacity: 0, y: 20 }}
                      >
                        <ProfileView 
                            onOpenSettings={() => setShowSettings(true)}
                            onOpenHelp={() => setShowHelp(true)}
                        />
                      </motion.div>
                    )}
                  </AnimatePresence>
                </main>

                <BottomNavigation 
                  items={NAV_ITEMS} 
                  activeTab={activeTab} 
                  onTabChange={setActiveTab} 
                />
             </div>

             {/* Overlays - Stacked Order Matters */}
             
             {/* 1. Settings View */}
             <AnimatePresence>
                {showSettings && (
                    <motion.div
                        key="settings"
                        initial={{ opacity: 0, x: "100%" }}
                        animate={{ opacity: 1, x: 0 }}
                        exit={{ opacity: 0, x: "100%" }}
                        transition={{ type: "spring", damping: 30, stiffness: 200 }}
                        className="absolute inset-0 z-50 bg-[#FDF7FF]"
                    >
                        <SettingsView onBack={() => setShowSettings(false)} />
                    </motion.div>
                )}
             </AnimatePresence>

             {/* 2. Help View */}
             <AnimatePresence>
                {showHelp && (
                    <motion.div
                        key="help"
                        initial={{ opacity: 0, x: "100%" }}
                        animate={{ opacity: 1, x: 0 }}
                        exit={{ opacity: 0, x: "100%" }}
                        transition={{ type: "spring", damping: 30, stiffness: 200 }}
                        className="absolute inset-0 z-50 bg-[#FDF7FF]"
                    >
                        <HelpView onBack={() => setShowHelp(false)} />
                    </motion.div>
                )}
             </AnimatePresence>

             {/* 3. Event Detail Overlay */}
             <AnimatePresence>
                {selectedEvent && (
                    <motion.div
                        key="event-detail"
                        initial={{ opacity: 0, y: "20%" }}
                        animate={{ opacity: 1, y: 0 }}
                        exit={{ opacity: 0, y: "100%" }}
                        transition={{ type: "spring", damping: 25, stiffness: 200 }}
                        className="absolute inset-0 z-50 bg-white"
                    >
                        <EventDetailView event={selectedEvent} onBack={() => setSelectedEvent(null)} />
                    </motion.div>
                )}
             </AnimatePresence>

             {/* 4. Digital ID Overlay (Highest Priority) */}
             <AnimatePresence>
                {showDigitalId && (
                    <motion.div
                        key="digital-id"
                        initial={{ opacity: 0, y: "100%" }}
                        animate={{ opacity: 1, y: 0 }}
                        exit={{ opacity: 0, y: "100%" }}
                        transition={{ type: "spring", damping: 25, stiffness: 200 }}
                        className="absolute inset-0 z-50 bg-[#1D192B]"
                    >
                        <DigitalIdView onBack={() => setShowDigitalId(false)} />
                    </motion.div>
                )}
             </AnimatePresence>

          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};

export default App;