import type { Timestamp } from "firebase/firestore";

export type EventTag = {
  id: string;
  name: string;
  color?: string | null;
  description?: string | null;
  sortOrder?: number | null;
  archived?: boolean;
};

export type EventRecord = {
  id: string;
  name: string;
  venueName: string;
  venueId?: string | null;
  price: number;
  maxTickets: number;
  ticketsSold: number;
  startTime?: Date | null;
  endTime?: Date | null;
  imageUrl?: string | null;
  description?: string | null;
  status?: string | null;
  category?: string | null;
  tagId?: string | null;
  tagName?: string | null;
  isFeatured?: boolean;
  organizerId?: string | null;
  createdAt?: Date | null;
  updatedAt?: Date | null;
};

export type EventPayload = {
  name: string;
  venueName: string;
  venueId?: string | null;
  price: number;
  maxTickets: number;
  startTime: Date | null;
  endTime: Date | null;
  imageUrl?: string | null;
  description?: string | null;
  status?: string | null;
  category?: string | null;
  tagId?: string | null;
  tagName?: string | null;
  isFeatured?: boolean;
};

export type FirestoreEvent = Omit<EventRecord, "startTime" | "endTime" | "createdAt" | "updatedAt"> & {
  startTime?: Timestamp | null;
  endTime?: Timestamp | null;
  createdAt?: Timestamp | null;
  updatedAt?: Timestamp | null;
  tags?: string[];
};

export type ScannerRecord = {
  id: string;
  email: string;
  displayName: string;
  venueId?: string | null;
  venueName?: string | null;
  venues?: string[];
  active: boolean;
  createdAt?: Date | null;
  lastSignInAt?: Date | null;
  notes?: string | null;
};

export type FirestoreScanner = Omit<ScannerRecord, "createdAt" | "lastSignInAt"> & {
  createdAt?: Timestamp | null;
  lastSignInAt?: Timestamp | null;
};

export type ScannerPayload = {
  email: string;
  displayName: string;
  venueId?: string | null;
  notes?: string | null;
  active?: boolean;
};
