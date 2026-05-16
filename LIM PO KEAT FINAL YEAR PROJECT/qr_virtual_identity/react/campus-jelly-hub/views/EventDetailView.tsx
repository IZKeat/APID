
import React, { useEffect, useState } from 'react';
import { motion, useScroll, useTransform, AnimatePresence } from 'framer-motion';
import { ArrowLeft, Calendar, MapPin, Users, Share2, Ticket, CheckCircle, Loader2, PartyPopper } from 'lucide-react';
import { Event } from '../types';
import { db } from '../services/db';

interface EventDetailViewProps {
  event: Event;
  onBack: () => void;
  onOpenQr?: () => void; // Optional if we want to open ticket directly
}

export const EventDetailView: React.FC<EventDetailViewProps> = ({ event, onBack, onOpenQr }) => {
  const { scrollY } = useScroll();
  const imageY = useTransform(scrollY, [0, 300], [0, 150]);
  const headerOpacity = useTransform(scrollY, [0, 200], [0, 1]);

  const [hasJoined, setHasJoined] = useState(false);
  const [isBooking, setIsBooking] = useState(false);
  const [showConfetti, setShowConfetti] = useState(false);

  useEffect(() => {
    const checkStatus = async () => {
        const joined = await db.hasJoined(event.id);
        setHasJoined(joined);
    };
    checkStatus();
  }, [event.id]);

  const handleBooking = async () => {
      if (hasJoined) {
          // If already joined, view ticket (which usually means open QR)
          if (onOpenQr) onOpenQr();
          return;
      }

      setIsBooking(true);
      const result = await db.bookEvent(event);
      
      if (result.success) {
          setShowConfetti(true);
          setHasJoined(true);
          setTimeout(() => {
              setShowConfetti(false);
              // Optional: Redirect to ticket view
          }, 3000);
      } else {
          alert(result.message || "Booking failed");
      }
      setIsBooking(false);
  };

  return (
    <div className="min-h-screen bg-white text-[#1D192B] flex flex-col relative z-50">
      
      {/* Sticky Header Bar */}
      <motion.div 
        style={{ opacity: headerOpacity }}
        className="fixed top-0 left-0 right-0 h-24 bg-[#1D192B]/90 backdrop-blur-md z-40 flex items-end pb-4 px-6"
      >
        <span className="text-white font-bold text-lg truncate ml-12">{event.title}</span>
      </motion.div>

      {/* Floating Back Button */}
      <motion.button
        initial={{ opacity: 0, scale: 0.8 }}
        animate={{ opacity: 1, scale: 1 }}
        whileTap={{ scale: 0.9 }}
        onClick={onBack}
        className="fixed top-12 left-6 z-50 w-10 h-10 bg-white/20 backdrop-blur-lg border border-white/30 rounded-full flex items-center justify-center text-white shadow-lg"
      >
        <ArrowLeft size={20} />
      </motion.button>

      {/* Confetti Overlay */}
      <AnimatePresence>
          {showConfetti && (
              <motion.div 
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                className="fixed inset-0 z-[60] flex items-center justify-center bg-black/40 pointer-events-none"
              >
                  <div className="bg-white p-6 rounded-[32px] flex flex-col items-center shadow-2xl animate-bounce">
                      <PartyPopper size={48} className="text-yellow-500 mb-2" />
                      <h2 className="text-xl font-bold text-[#1D192B]">You're Going!</h2>
                      <p className="text-sm text-gray-500">Ticket added to My Booking</p>
                  </div>
              </motion.div>
          )}
      </AnimatePresence>

      {/* Parallax Hero Section */}
      <div className="relative h-[350px] overflow-hidden bg-[#1D192B]">
        <motion.div style={{ y: imageY }} className="absolute inset-0">
             <div className={`w-full h-full opacity-60 ${event.color.replace('text', 'bg').split(' ')[0]} bg-gradient-to-br from-black/50 via-transparent to-transparent`} />
             <img 
                src={`https://api.dicebear.com/9.x/shapes/svg?seed=${event.id}&backgroundColor=${event.color.includes('green') ? 'C3EED0' : 'EADDFF'}`}
                className="w-full h-full object-cover opacity-50 mix-blend-overlay"
                alt="Event Cover"
             />
        </motion.div>
        
        <div className="absolute inset-0 bg-gradient-to-t from-[#1D192B] via-transparent to-black/30" />

        <div className="absolute bottom-0 left-0 right-0 p-6 pb-12">
            <motion.div 
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.2 }}
                className="flex items-center gap-2 mb-3"
            >
                <span className={`px-3 py-1 rounded-lg text-xs font-bold uppercase tracking-wider bg-white/10 text-white backdrop-blur-md border border-white/10`}>
                    {event.tag}
                </span>
                {hasJoined && (
                    <div className="px-3 py-1 rounded-lg text-xs font-bold uppercase tracking-wider bg-[#00639B] text-white flex items-center gap-1.5">
                        <div className="w-1.5 h-1.5 rounded-full bg-white animate-pulse" />
                        Joined
                    </div>
                )}
            </motion.div>
            
            <motion.h1 
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.3 }}
                className="text-3xl font-black text-white leading-tight drop-shadow-lg"
            >
                {event.title}
            </motion.h1>
            <motion.p 
                 initial={{ opacity: 0 }}
                 animate={{ opacity: 1 }}
                 transition={{ delay: 0.4 }}
                 className="text-white/70 font-medium mt-2"
            >
                Organized by APU Mobile Dev Club
            </motion.p>
        </div>
      </div>

      {/* Content Sheet */}
      <div className="relative -mt-8 bg-white rounded-t-[32px] p-6 pb-32 flex-1 shadow-[0_-10px_40px_rgba(0,0,0,0.2)]">
        
        {/* Jelly Widgets Scroll */}
        <div className="flex gap-4 overflow-x-auto no-scrollbar -mx-6 px-6 pb-6 pt-2">
            <InfoWidget 
                icon={Calendar} 
                label="Date & Time" 
                title={event.fullDate} 
                subtitle={event.time} 
                color="bg-[#E8DEF8] text-[#1D192B]"
                delay={0.1}
            />
            <InfoWidget 
                icon={MapPin} 
                label="Location" 
                title="APU Campus" 
                subtitle={event.location} 
                color="bg-[#FFD8E4] text-[#31111D]"
                delay={0.2}
            />
            <InfoWidget 
                icon={Users} 
                label="Capacity" 
                title={`${event.capacity?.current || 41}/${event.capacity?.total || 50} attendees`} 
                subtitle={`${(event.capacity?.total || 50) - (event.capacity?.current || 41)} slots remaining`} 
                color="bg-[#C3EED0] text-[#053916]"
                delay={0.3}
            />
        </div>

        {/* Description */}
        <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.4 }}
            className="space-y-4 mt-2"
        >
            <h3 className="text-xl font-bold text-[#6750A4]">About This Event</h3>
            <p className="text-[#49454F] leading-relaxed">
                {event.description || "Hands-on workshop! Suitable for beginners. Bring your laptop and let's code!"}
            </p>
        </motion.div>

        {/* Tags */}
        <motion.div 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.5 }}
            className="mt-8"
        >
            <h3 className="text-sm font-bold text-[#49454F] mb-3">Tags</h3>
            <div className="flex flex-wrap gap-2">
                {['#workshop', '#mobile', '#coding', `#${event.tag.toLowerCase()}`].map(tag => (
                    <span key={tag} className="px-4 py-1.5 rounded-full border border-gray-200 text-xs font-bold text-gray-500">
                        {tag}
                    </span>
                ))}
            </div>
        </motion.div>

      </div>

      {/* Sticky Bottom Action Bar */}
      <motion.div 
        initial={{ y: 100 }}
        animate={{ y: 0 }}
        className="fixed bottom-0 left-0 right-0 p-4 bg-white/80 backdrop-blur-xl border-t border-gray-100 z-50 flex items-center gap-4"
      >
        <button className="w-12 h-12 flex items-center justify-center rounded-2xl bg-[#F3EDF7] text-[#1D192B] hover:bg-[#E8DEF8] transition-colors">
            <Share2 size={20} />
        </button>
        
        <button 
            onClick={handleBooking}
            disabled={isBooking}
            className={`
                flex-1 h-12 rounded-[20px] font-bold text-sm flex items-center justify-center gap-2 shadow-lg transition-all active:scale-95
                ${hasJoined 
                    ? 'bg-[#00639B] text-white shadow-blue-900/20' 
                    : 'bg-[#16A34A] hover:bg-[#15803d] text-white shadow-green-900/20'
                }
            `}
        >
            {isBooking ? (
                <Loader2 size={18} className="animate-spin" />
            ) : hasJoined ? (
                <>
                    <Ticket size={18} />
                    View Ticket
                </>
            ) : (
                <>
                    <CheckCircle size={18} />
                    Book Slot
                </>
            )}
        </button>
      </motion.div>

    </div>
  );
};

const InfoWidget: React.FC<{ icon: any, label: string, title: string, subtitle: string, color: string, delay: number }> = ({ 
    icon: Icon, label, title, subtitle, color, delay 
}) => (
    <motion.div 
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ type: "spring", stiffness: 300, damping: 20, delay }}
        className={`min-w-[200px] p-4 rounded-[24px] ${color} flex flex-col justify-between h-32 snap-start`}
    >
        <div className="w-8 h-8 rounded-full bg-white/40 flex items-center justify-center mb-2">
            <Icon size={16} />
        </div>
        <div>
            <span className="text-[10px] font-bold uppercase tracking-wider opacity-60">{label}</span>
            <p className="font-bold text-sm leading-tight mt-0.5 line-clamp-2">{title}</p>
            <p className="text-xs opacity-70 mt-1">{subtitle}</p>
        </div>
    </motion.div>
);
