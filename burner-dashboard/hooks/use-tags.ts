"use client";

import { useEffect, useState } from "react";
import { listenToTags } from "@/lib/firestore/events";
import type { EventTag } from "@/lib/types";

export function useTags() {
  const [tags, setTags] = useState<EventTag[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    const unsubscribe = listenToTags(
      (data) => {
        setTags(data);
        setLoading(false);
      },
      (err) => {
        setError(err);
        setLoading(false);
      }
    );

    return () => unsubscribe();
  }, []);

  return { tags, loading, error };
}
