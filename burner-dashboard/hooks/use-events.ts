"use client";

import { useEffect, useState } from "react";
import { listenToEvents } from "@/lib/firestore/events";
import type { EventRecord } from "@/lib/types";

export function useEvents() {
  const [events, setEvents] = useState<EventRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    const unsubscribe = listenToEvents(
      (data) => {
        setEvents(data);
        setLoading(false);
      },
      (err) => {
        setError(err);
        setLoading(false);
      }
    );

    return () => {
      unsubscribe();
    };
  }, []);

  return { events, loading, error };
}
