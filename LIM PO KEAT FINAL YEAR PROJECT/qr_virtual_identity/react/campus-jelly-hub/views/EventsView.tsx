
import React, { useState, useEffect } from 'react';
import { MapPin, Calendar, Ticket, CheckCircle2, Clock, ChevronRight, QrCode, XCircle, Filter, Loader2 } from 'lucide-react';
import { JellyCard } from '../components/ui/JellyCard';
import { motion, AnimatePresence, Variants } from 'framer-motion';
import { Event } from '../types';
import { db, TicketSchema } from '../services/db';

// --- ANIMATION VARIANTS ---

const containerVariants: Variants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.08,
      delayChildren: 0.05
    }
  }
};

const itemVariants: Variants = {
  hidden: { opacity: 0, y: 30, scale: 0.95 },
  visible: { 
    opacity: 1, 
    y: 0, 
    scale: 1,
    transition: { type: "spring", stiffness: 300, damping: 24 }
  }
};

const filterChipVariants: Variants = {
    tap: { scale: 0.9 },
    hover: { scale: 1.05 }
};

// --- COMPONENTS ---

interface EventsViewProps {
    onOpenDigitalId: () => void;
    onEventSelect: (event: Event) => void;
}

export const EventsView: React.FC<EventsViewProps> = ({ onOpenDigitalId, onEventSelect }) => {
  const [activeTab, setActiveTab] = useState<'all' | 'booking'>('booking'); 
  const [ticketFilter, setTicketFilter] = useState<'All' | 'Active' | 'Attended' | 'Cancelled'>('All');
  
  // Async Data State
  const [events, setEvents] = useState<Event[]>([]);
  const [tickets, setTickets] = useState<TicketSchema[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Fetch Data on Mount and when Tab changes
  useEffect(() => {
    const fetchData = async () => {
        setIsLoading(true);
        try {
            if (activeTab === 'all') {
                const fetchedEvents = await db.getEvents();
                setEvents(fetchedEvents);
            } else {
                const fetchedTickets = await db.getMyTickets();
                setTickets(fetchedTickets);
            }
        } catch (error) {
            console.error("Failed to fetch data", error);
        } finally {
            setIsLoading(false);
        }
    };
    fetchData();
  }, [activeTab]);

  const filteredTickets = tickets.filter(t => {
      if (ticketFilter === 'All') return true;
      return t.status.toLowerCase() === ticketFilter.toLowerCase();
  });

  return (
    <div className="pb-32 px-6 pt-2 min-h-screen">
      <motion.div 
        initial={{ opacity: 0, y: -10 }}
        animate={{ opacity: 1, y: 0 }}
        className="flex flex-col gap-6"
      >
        {/* Main Tab Toggle */}
        <div className="flex flex-col items-center space-y-4 mb-2">
            <h2 className="text-2xl font-bold text-[#1D192B]">Events & Tickets</h2>
            
            <div className="bg-white p-1.5 rounded-full flex relative shadow-sm border border-gray-100 w-full max-w-xs">
                 <motion.div 
                    layoutId="main-tab-pill"
                    className="absolute top-1.5 bottom-1.5 bg-[#E8DEF8] rounded-full z-0"
                    initial={false}
                    transition={{ type: "spring", stiffness: 500, damping: 30 }}
                    style={{
                        left: activeTab === 'all' ? '6px' : '50%',
                        width: 'calc(50% - 6px)'
                    }}
                 />

                 <button 
                    onClick={() => setActiveTab('all')}
                    className={`flex-1 relative z-10 py-2.5 text-sm font-bold text-center rounded-full transition-colors ${activeTab === 'all' ? 'text-[#1D192B]' : 'text-gray-500'}`}
                 >
                    All Events
                 </button>
                 <button 
                    onClick={() => setActiveTab('booking')}
                    className={`flex-1 relative z-10 py-2.5 text-sm font-bold text-center rounded-full transition-colors ${activeTab === 'booking' ? 'text-[#1D192B]' : 'text-gray-500'}`}
                 >
                    My Booking
                 </button>
            </div>
        </div>

        {/* Content Area */}
        <AnimatePresence mode="wait">
            {isLoading ? (
                <div key="loading" className="flex flex-col gap-4 mt-4">
                    {[1, 2, 3].map(i => (
                        <div key={i} className="h-32 bg-gray-100 rounded-[32px] animate-pulse" />
                    ))}
                </div>
            ) : activeTab === 'all' ? (
                // --- EVENTS LIST ---
                <motion.div 
                    key="all-events"
                    variants={containerVariants}
                    initial="hidden"
                    animate="visible"
                    exit={{ opacity: 0, x: -20 }}
                    className="space-y-4"
                >
                    {events.map((event) => (
                        <motion.div key={event.id} variants={itemVariants}>
                            <JellyCard 
                                title="" 
                                colorClass={`${event.color}`} 
                                className="!p-0 border-none overflow-hidden"
                                onClick={() => onEventSelect(event)}
                            >
                                <div className="flex items-stretch">
                                    <div className="w-24 bg-black/5 flex flex-col items-center justify-center p-4 border-r border-black/5">
                                        <span className="text-xs font-bold uppercase tracking-widest opacity-60">{event.month}</span>
                                        <span className="text-3xl font-black leading-none">{event.date}</span>
                                    </div>
                                    <div className="flex-1 p-5 flex flex-col justify-center relative">
                                        <div className="absolute top-4 right-4">
                                            <span className="bg-white/40 backdrop-blur-sm px-2 py-1 rounded-lg text-[10px] font-bold uppercase tracking-wider border border-white/20">
                                                {event.tag}
                                            </span>
                                        </div>
                                        <h3 className="text-lg font-bold leading-tight mb-2 pr-12">{event.title}</h3>
                                        <div className="flex items-center gap-2 opacity-70">
                                            <MapPin size={14} />
                                            <span className="text-xs font-medium truncate">{event.location}</span>
                                        </div>
                                    </div>
                                </div>
                            </JellyCard>
                        </motion.div>
                    ))}
                </motion.div>
            ) : (
                // --- TICKETS LIST (MY BOOKING) ---
                <motion.div 
                    key="my-booking"
                    initial={{ opacity: 0, x: 20 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: 20 }}
                    className="flex flex-col gap-6"
                >
                    {/* Ticket Filters */}
                    <div className="space-y-3">
                         <div className="flex items-center gap-2 text-[#49454F]">
                             <Filter size={16} />
                             <span className="text-sm font-bold">Filter Tickets</span>
                         </div>
                         <div className="flex gap-3 overflow-x-auto no-scrollbar pb-2 -mx-6 px-6">
                            {['All', 'Active', 'Attended', 'Cancelled'].map((filter) => {
                                const isActive = ticketFilter === filter;
                                return (
                                    <motion.button
                                        key={filter}
                                        onClick={() => setTicketFilter(filter as any)}
                                        variants={filterChipVariants}
                                        whileTap="tap"
                                        whileHover="hover"
                                        className={`
                                            px-5 py-2 rounded-xl text-sm font-bold whitespace-nowrap border transition-colors
                                            ${isActive 
                                                ? 'bg-[#6750A4] text-white border-[#6750A4] shadow-md shadow-[#6750A4]/20' 
                                                : 'bg-white text-[#49454F] border-gray-200 hover:bg-[#F3EDF7]'
                                            }
                                        `}
                                    >
                                        {filter}
                                    </motion.button>
                                )
                            })}
                         </div>
                    </div>

                    {/* Tickets List */}
                    <motion.div 
                        layout 
                        className="space-y-4"
                    >
                        <AnimatePresence mode="popLayout">
                            {filteredTickets.length > 0 ? (
                                filteredTickets.map((ticket) => (
                                    <motion.div
                                        key={ticket.id}
                                        layout
                                        initial={{ opacity: 0, scale: 0.8 }}
                                        animate={{ opacity: 1, scale: 1 }}
                                        exit={{ opacity: 0, scale: 0.8 }}
                                        transition={{ type: "spring", stiffness: 300, damping: 25 }}
                                    >
                                        <TicketCard ticket={ticket} onOpenQr={onOpenDigitalId} />
                                    </motion.div>
                                ))
                            ) : (
                                <motion.div 
                                    initial={{ opacity: 0 }} 
                                    animate={{ opacity: 1 }}
                                    className="py-12 text-center text-gray-400"
                                >
                                    <p>No tickets found in this category.</p>
                                </motion.div>
                            )}
                        </AnimatePresence>
                    </motion.div>
                </motion.div>
            )}
        </AnimatePresence>
      </motion.div>
    </div>
  );
};

// --- SUB-COMPONENT: TICKET CARD ---

const TicketCard: React.FC<{ ticket: TicketSchema, onOpenQr: () => void }> = ({ ticket, onOpenQr }) => {
    // Determine visuals based on status
    const isAttended = ticket.status === 'attended';
    const isCancelled = ticket.status === 'cancelled';
    const isActive = ticket.status === 'active';

    let bgClass = "bg-white";
    let statusColor = "bg-gray-100 text-gray-600";
    let StatusIcon = CheckCircle2;
    let statusLabel: string = ticket.status;

    if (isActive) {
        bgClass = "bg-gradient-to-br from-[#F0FDF4] to-[#DCFCE7] border-green-100"; // Fresh Mint
        statusColor = "bg-[#16A34A] text-white";
        StatusIcon = CheckCircle2;
        statusLabel = "ACTIVE";
    } else if (isAttended) {
        bgClass = "bg-gradient-to-br from-[#F0F9FF] to-[#E0F2FE] border-blue-100"; // Cool Blue
        statusColor = "bg-[#0284C7] text-white";
        StatusIcon = CheckCircle2;
        statusLabel = "ATTENDED";
    } else if (isCancelled) {
         bgClass = "bg-gray-50 border-gray-100 opacity-80";
         statusColor = "bg-gray-200 text-gray-500";
         StatusIcon = XCircle;
         statusLabel = "CANCELLED";
    }

    return (
        <JellyCard 
            title="" 
            colorClass={`${bgClass} border`} 
            className="!p-0 !rounded-[24px] overflow-visible"
        >
            <div className="p-5 pb-4">
                {/* Header Row */}
                <div className="flex justify-between items-start gap-3 mb-4">
                    <h3 className={`text-lg font-bold leading-tight ${isCancelled ? 'text-gray-500 line-through' : 'text-[#1D192B]'}`}>
                        {ticket.title}
                    </h3>
                    <div className={`flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-[10px] font-bold tracking-wider shadow-sm ${statusColor}`}>
                        <StatusIcon size={12} strokeWidth={3} />
                        <span className="uppercase">{statusLabel}</span>
                    </div>
                </div>

                {/* Metadata Grid */}
                <div className="space-y-2.5">
                    <div className="flex items-center gap-3 text-sm text-[#49454F]">
                        <Calendar size={16} className="text-[#6750A4]" />
                        <span className="font-medium">{ticket.date}</span>
                        <span className="text-gray-300 mx-1">•</span>
                        <Clock size={16} className="text-[#6750A4]" />
                        <span className="font-medium">{ticket.time}</span>
                    </div>
                    <div className="flex items-start gap-3 text-sm text-[#49454F]">
                        <MapPin size={16} className="text-[#6750A4] mt-0.5 shrink-0" />
                        <span className="font-medium leading-snug">{ticket.location}</span>
                    </div>
                    <div className="flex items-center gap-3 text-xs font-bold text-[#6750A4] mt-1">
                         <div className="w-4 flex justify-center"><div className="w-1.5 h-1.5 rounded-full bg-[#D0BCFF]" /></div>
                         <span className="uppercase tracking-wide">{ticket.type}</span>
                    </div>
                </div>
            </div>

            {/* Action Footer (Cutout Look) */}
            {isActive && (
                <div className="mx-2 mb-2">
                    <motion.button 
                        whileTap={{ scale: 0.97 }}
                        onClick={(e) => {
                            e.stopPropagation();
                            onOpenQr();
                        }}
                        className="w-full bg-[#C3EED0] hover:bg-[#b0eac2] text-[#053916] py-3 rounded-[20px] font-bold text-sm flex items-center justify-between px-6 transition-colors group relative overflow-hidden"
                    >
                         <div className="flex items-center gap-3 relative z-10">
                            <QrCode size={18} />
                            <span>Tap to view QR ticket</span>
                         </div>
                         <div className="bg-white/20 p-1.5 rounded-full relative z-10">
                             <ChevronRight size={16} />
                         </div>
                         
                         {/* Liquid effect inside button */}
                         <div className="absolute inset-0 bg-white/20 translate-y-full group-hover:translate-y-0 transition-transform duration-300 ease-out" />
                    </motion.button>
                </div>
            )}

            {isAttended && (
                 <div className="bg-black/5 mx-2 mb-2 p-3 rounded-[20px] flex items-center justify-center gap-2 border border-black/5">
                     <CheckCircle2 size={16} className="text-[#053916]" />
                     <span className="text-xs font-bold text-[#053916] uppercase tracking-wide">Check-in Completed</span>
                 </div>
            )}
        </JellyCard>
    );
};
