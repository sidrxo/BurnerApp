"use client";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase"; // Importing your existing client

export default function Index() {
  const router = useRouter();
  const [isChecking, setIsChecking] = useState(true);

  useEffect(() => {
    const checkAuth = async () => {
      // 1. Check the current session immediately
      const { data: { session } } = await supabase.auth.getSession();

      if (session) {
        router.replace("/overview");
      } else {
        router.replace("/login");
      }
      setIsChecking(false);
    };

    checkAuth();

    // 2. Set up a listener for changes (e.g. if they sign out in another tab)
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      if (session) {
        router.replace("/overview");
      } else {
        router.replace("/login");
      }
    });

    // Cleanup subscription on unmount
    return () => subscription.unsubscribe();
  }, [router]);

  // Loading UI
  if (isChecking) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center space-y-4">
          <div className="text-4xl">⏳</div>
          <p className="text-muted-foreground">Loading...</p>
        </div>
      </div>
    );
  }

  return null;
}