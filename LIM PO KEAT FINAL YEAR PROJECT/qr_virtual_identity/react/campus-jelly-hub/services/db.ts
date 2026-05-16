
import { Event } from '../types';

// --- INITIAL MOCK DATA ---
const INITIAL_EVENTS: Event[] = [
  {
    id: 1,
    title: "Mobile App Development Workshop",
    date: "15",
    month: "Nov",
    fullDate: "Saturday, November 15, 2025",
    time: "10:00 - 14:00",
    location: "APU Computer Lab C - Level 3",
    tag: "Workshop",
    color: "bg-[#EADDFF] text-[#21005D]",
    capacity: { current: 41, total: 50 },
    description: "Hands-on Flutter workshop! Learn to build your first mobile app from scratch. Suitable for beginners. We will cover Dart basics, Widget trees, and State management. Bring your laptop!"
  },
  {
    id: 2,
    title: "APU Tech Talk 2025: AI & Future of Work",
    date: "20",
    month: "Nov",
    fullDate: "Thursday, November 20, 2025",
    time: "14:00 - 16:00",
    location: "APU Auditorium - Block A",
    tag: "Talk",
    color: "bg-[#C3EED0] text-[#053916]",
    capacity: { current: 120, total: 200 },
    description: "Join industry leaders from Google, Microsoft, and Amazon as they discuss the impact of Artificial Intelligence on the future job market. Q&A session included."
  },
  {
    id: 3,
    title: "Cybersecurity Challenge 2025",
    date: "22",
    month: "Nov",
    fullDate: "Saturday, November 22, 2025",
    time: "09:00 - 18:00",
    location: "APU Lab D - Block C",
    tag: "Competition",
    color: "bg-[#FFD8E4] text-[#31111D]",
    capacity: { current: 18, total: 20 },
    description: "A Capture The Flag (CTF) competition for cybersecurity enthusiasts. Test your skills in penetration testing, cryptography, and forensics. Win cash prizes!"
  },
  {
    id: 4,
    title: "Alumni Networking Night",
    date: "28",
    month: "Nov",
    fullDate: "Friday, November 28, 2025",
    time: "19:00 - 22:00",
    location: "APU Conference Hall",
    tag: "Social",
    color: "bg-[#D7E3FF] text-[#001B3D]",
    capacity: { current: 80, total: 100 },
    description: "Connect with successful APU alumni. A great opportunity to find mentors, internship opportunities, and expand your professional network. Dinner provided."
  },
  {
    id: 5,
    title: "Campus Open Day 2025",
    date: "05",
    month: "Dec",
    fullDate: "Friday, December 05, 2025",
    time: "08:00 - 17:00",
    location: "Campus Wide",
    tag: "Event",
    color: "bg-[#FFDBCF] text-[#380D00]",
    capacity: { current: 500, total: 1000 },
    description: "Explore the campus, visit faculties, and enjoy carnival games. Open to all students and the public."
  }
];

export interface TicketSchema {
  id: number;
  eventId: number;
  title: string;
  date: string;
  time: string;
  location: string;
  type: string;
  status: 'active' | 'attended' | 'cancelled';
  qrCodeData: string;
}

// --- DATABASE SERVICE ---
class MockDatabase {
  private readonly STORAGE_KEY_EVENTS = 'jelly_hub_events';
  private readonly STORAGE_KEY_TICKETS = 'jelly_hub_tickets';

  constructor() {
    this.init();
  }

  private init() {
    if (!localStorage.getItem(this.STORAGE_KEY_EVENTS)) {
      localStorage.setItem(this.STORAGE_KEY_EVENTS, JSON.stringify(INITIAL_EVENTS));
    }
    if (!localStorage.getItem(this.STORAGE_KEY_TICKETS)) {
      // Seed some initial tickets
      const initialTickets: TicketSchema[] = [
        {
          id: 101,
          eventId: 2, // Matches Tech Talk
          title: "APU Tech Talk 2025: AI & Future of Work",
          date: "Nov 20, 2025",
          time: "14:00 - 16:00",
          location: "APU Auditorium - Block A",
          type: "Talk",
          status: 'attended',
          qrCodeData: 'TICKET-101-ATTENDED'
        }
      ];
      localStorage.setItem(this.STORAGE_KEY_TICKETS, JSON.stringify(initialTickets));
    }
  }

  // Simulate Network Delay
  private async delay(ms: number = 800) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  // --- API METHODS ---

  async getEvents(): Promise<Event[]> {
    await this.delay(600); // Simulate fetch latency
    const data = localStorage.getItem(this.STORAGE_KEY_EVENTS);
    return data ? JSON.parse(data) : [];
  }

  async getMyTickets(): Promise<TicketSchema[]> {
    await this.delay(600);
    const data = localStorage.getItem(this.STORAGE_KEY_TICKETS);
    return data ? JSON.parse(data) : [];
  }

  async getEventById(id: number): Promise<Event | undefined> {
    await this.delay(300);
    const events = await this.getEvents();
    return events.find(e => e.id === id);
  }

  async bookEvent(event: Event): Promise<{ success: boolean; ticket?: TicketSchema; message?: string }> {
    await this.delay(1200); // Booking takes a bit longer

    const events = await this.getEvents();
    const targetEventIndex = events.findIndex(e => e.id === event.id);

    if (targetEventIndex === -1) return { success: false, message: "Event not found." };

    const targetEvent = events[targetEventIndex];

    // Check Capacity
    if (targetEvent.capacity && targetEvent.capacity.current >= targetEvent.capacity.total) {
      return { success: false, message: "Event is fully booked." };
    }

    // Check if already booked
    const tickets = await this.getMyTickets();
    const existingTicket = tickets.find(t => t.eventId === event.id && t.status !== 'cancelled');
    if (existingTicket) {
      return { success: false, message: "You already have a ticket for this event." };
    }

    // 1. Create Ticket
    const newTicket: TicketSchema = {
      id: Date.now(), // Simple ID generation
      eventId: event.id,
      title: event.title,
      date: `${event.month} ${event.date}, 2025`, // Simplified date format
      time: event.time,
      location: event.location,
      type: event.tag,
      status: 'active',
      qrCodeData: `TICKET-${event.id}-${Date.now()}`
    };

    // 2. Update Event Capacity
    if (targetEvent.capacity) {
        targetEvent.capacity.current += 1;
    }
    events[targetEventIndex] = targetEvent;

    // 3. Save to "DB"
    tickets.unshift(newTicket); // Add to top
    localStorage.setItem(this.STORAGE_KEY_EVENTS, JSON.stringify(events));
    localStorage.setItem(this.STORAGE_KEY_TICKETS, JSON.stringify(tickets));

    return { success: true, ticket: newTicket };
  }

  async hasJoined(eventId: number): Promise<boolean> {
      // No delay needed for this check usually, but let's keep it consistent or fast
      const data = localStorage.getItem(this.STORAGE_KEY_TICKETS);
      const tickets: TicketSchema[] = data ? JSON.parse(data) : [];
      return tickets.some(t => t.eventId === eventId && t.status !== 'cancelled');
  }
}

export const db = new MockDatabase();
