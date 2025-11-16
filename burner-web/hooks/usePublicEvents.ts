"use client";

import { useEffect, useState } from "react";
import {
  collection,
  query,
  where,
  orderBy,
  getDocs,
  Timestamp,
  limit,
} from "firebase/firestore";
import { db } from "@/lib/firebase";

export interface Event {
  id: string;
  name: string;
  description?: string | null;
  venue?: string;
  venueId?: string | null;
  startTime?: Timestamp;
  endTime?: Timestamp | null;
  price: number;
  maxTickets: number;
  ticketsSold: number;
  isFeatured?: boolean;
  imageUrl?: string | null;
  status?: string | null;
  category?: string | null;
  tags?: string[];
  coordinates?: { latitude: number; longitude: number } | null;
}

// Simple in-memory cache to reduce Firestore reads
let eventsCache: { data: Event[]; timestamp: number } | null = null;
const CACHE_TTL = 5 * 60 * 1000; // 5 minutes
const MAX_EVENTS = 100; // Limit events to prevent large reads

export function usePublicEvents() {
  const [events, setEvents] = useState<Event[]>([]);
  const [featuredEvents, setFeaturedEvents] = useState<Event[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchEvents = async () => {
      try {
        setLoading(true);

        // Check cache first
        if (eventsCache && Date.now() - eventsCache.timestamp < CACHE_TTL) {
          setEvents(eventsCache.data);
          setFeaturedEvents(eventsCache.data.filter((event) => event.isFeatured));
          setError(null);
          setLoading(false);
          return;
        }

        const eventsRef = collection(db, "events");

        // Only fetch active events, ordered by start time
        // This reduces unnecessary reads of past/inactive events
        const q = query(
          eventsRef,
          where("status", "==", "active"),
          orderBy("startTime", "desc"),
          limit(MAX_EVENTS)
        );

        const snapshot = await getDocs(q);
        const eventsData = snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        })) as Event[];

        // Update cache
        eventsCache = {
          data: eventsData,
          timestamp: Date.now(),
        };

        setEvents(eventsData);
        setFeaturedEvents(eventsData.filter((event) => event.isFeatured));
        setError(null);
      } catch (err) {
        console.error("Error fetching events:", err);
        setError("Failed to load events");
      } finally {
        setLoading(false);
      }
    };

    fetchEvents();
  }, []);

  return { events, featuredEvents, loading, error };
}
