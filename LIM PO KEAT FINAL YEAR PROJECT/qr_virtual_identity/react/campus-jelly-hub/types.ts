
import { LucideIcon } from 'lucide-react';
import { ReactNode } from 'react';

export interface NavItem {
  id: string;
  label: string;
  icon: LucideIcon;
}

export interface ServiceCardProps {
  title: string;
  subtitle?: string;
  icon?: LucideIcon;
  colorClass: string;
  delay?: number;
  onClick?: () => void;
  className?: string;
  children?: ReactNode; // For custom content like notification preview
}

export interface Event {
  id: number;
  title: string;
  date: string; // e.g., "15"
  month: string; // e.g., "Nov"
  fullDate: string; // e.g., "Saturday, November 15, 2025"
  time: string; // e.g., "10:00 - 14:00"
  location: string;
  tag: string;
  color: string;
  description?: string;
  capacity?: {
      current: number;
      total: number;
  };
}
