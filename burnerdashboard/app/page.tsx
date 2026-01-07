"use client";
import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/components/useAuth";

export default function Index() {
  const router = useRouter();
  const { user, loading } = useAuth();

  useEffect(() => {
    // Only redirect to overview if user is authenticated
    // RequireAuth component handles showing login form when not authenticated
    if (!loading && user) {
      router.replace("/overview");
    }
  }, [user, loading, router]);

  // Show loading state while checking auth
  // If not authenticated, RequireAuth will handle showing the login form
  return (
    <div className="flex items-center justify-center min-h-screen">
      <div className="text-center space-y-4">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
        <p className="text-muted-foreground">Loading...</p>
      </div>
    </div>
  );
}