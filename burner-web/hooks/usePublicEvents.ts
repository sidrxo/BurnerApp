"use client";

import { useEffect, useState } from "react";
import {
  collection,
  query,
  where,
  orderBy,
  getDocs,
  Timestamp,
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

export function usePublicEvents() {
  const [events, setEvents] = useState<Event[]>([]);
  const [featuredEvents, setFeaturedEvents] = useState<Event[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchEvents = async () => {
      try {
        setLoading(true);
        const eventsRef = collection(db, "events");

        // Only fetch active/published events
        const q = query(
          eventsRef,
          where("status", "==", "published"),
          orderBy("startTime", "desc")
        );

        const snapshot = await getDocs(q);
        const eventsData = snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        })) as Event[];

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
