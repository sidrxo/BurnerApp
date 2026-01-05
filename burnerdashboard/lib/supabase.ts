// lib/supabase.ts - Supabase Configuration

import { createClient } from '@supabase/supabase-js';

// Validate environment variables
const requiredEnvVars = {
  NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL,
  NEXT_PUBLIC_SUPABASE_ANON_KEY: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
};

// Check for missing environment variables
const missingVars = Object.entries(requiredEnvVars)
  .filter(([key, value]) => !value)
  .map(([key]) => key);

if (missingVars.length > 0) {
  const errorMessage = `Missing required Supabase environment variables: ${missingVars.join(', ')}`;
  console.error('🔥 Supabase Configuration Error:', errorMessage);

  if (typeof window !== 'undefined') {
    // Client-side: Show user-friendly error
    alert('Application configuration error. Please contact support.');
  }

  throw new Error(errorMessage);
}

// Create Supabase client
export const supabase = createClient(
  requiredEnvVars.NEXT_PUBLIC_SUPABASE_URL!,
  requiredEnvVars.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: true,
    },
  }
);

// Export auth and storage helpers for convenience
export const auth = supabase.auth;
export const storage = supabase.storage;

// Export config for debugging (only in development)
if (process.env.NODE_ENV === 'development') {
  console.log('🔥 Supabase initialized successfully:', {
    url: requiredEnvVars.NEXT_PUBLIC_SUPABASE_URL,
  });
}

// Type definitions for database schema
export type Role = 'siteAdmin' | 'venueAdmin' | 'subAdmin' | 'scanner' | 'organiser' | 'user';

// Unified User interface (replaces both AppUser and Admin)
export interface AppUser {
  id: string;
  email: string | null;
  role: Role;
  venue_id?: string | null;
  active: boolean;
  name?: string | null;
  created_at?: string;
  last_login?: string;
  needs_password_reset?: boolean;
}

// Alias for backward compatibility
export type Admin = AppUser;

export interface Event {
  id: string;
  name: string;
  description: string | null;
  venue: string;
  venue_id: string | null;
  start_time: string;
  end_time: string;
  price: number;
  max_tickets: number;
  tickets_sold: number;
  is_featured: boolean;
  featured_priority: number | null;
  image_url: string | null;
  status: string;
  category: string | null;
  tags: string[] | null;
  coordinates: { latitude: number; longitude: number } | null;
  organizer_id: string | null;
  created_at: string;
  updated_at: string;
}

export interface Ticket {
  ticket_id: string;
  user_id: string;
  event_id: string;
  event_name: string;
  venue: string;
  venue_id: string | null;
  ticket_number: string;
  total_price: number;
  purchase_date: string;
  status: 'confirmed' | 'used' | 'cancelled' | 'deleted';
  used_at: string | null;
  scanned_by: string | null;
  scanned_by_email: string | null;
  start_time: string;
  qr_code: any;
  transferred_from: string | null;
  transferred_at: string | null;
}

export interface Venue {
  id: string;
  name: string;
  admins: string[];
  sub_admins?: string[];
  address: string | null;
  city: string | null;
  coordinates: { latitude: number; longitude: number } | null;
  capacity: number | null;
  contact_email: string | null;
  website: string | null;
  active: boolean;
  event_count?: number;
  created_at?: string;
}

export interface Tag {
  id: string;
  name: string;
  description: string | null;
  color: string | null;
  order: number;
  active: boolean;
  created_at: string;
  updated_at: string;
}

export interface OrganizerVenue {
  id: string;
  organizer_id: string;
  venue_id: string;
  created_at: string;
  created_by: string | null;
}
