"use client";

import { useEffect, useState } from "react";
import { listenToScanners } from "@/lib/firestore/scanners";
import type { ScannerRecord } from "@/lib/types";

export function useScanners() {
  const [scanners, setScanners] = useState<ScannerRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    const unsubscribe = listenToScanners(
      (data) => {
        setScanners(data);
        setLoading(false);
      },
      (err) => {
        setError(err);
        setLoading(false);
      }
    );

    return () => unsubscribe();
  }, []);

  return { scanners, loading, error };
}
