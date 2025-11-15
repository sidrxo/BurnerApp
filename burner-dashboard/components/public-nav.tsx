"use client";

import Link from "next/link";
import { useAuth } from "./useAuth";
import { useRouter } from "next/navigation";

export function PublicNav() {
  const { user } = useAuth();
  const router = useRouter();

  return (
    <nav className="fixed top-0 left-0 right-0 z-50 bg-black border-b border-white/10">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <Link href="/" className="flex items-center">
            <span className="text-2xl font-bold tracking-tight">BURNER</span>
          </Link>

          {/* Right side actions */}
          <div className="flex items-center gap-4">
            {user ? (
              <>
                <button
                  onClick={() => router.push("/my-tickets")}
                  className="text-sm font-medium hover:text-white/70 transition-colors"
                >
                  My Tickets
                </button>
                <button
                  onClick={() => router.push("/overview")}
                  className="text-sm font-medium hover:text-white/70 transition-colors"
                >
                  Dashboard
                </button>
              </>
            ) : (
              <button
                onClick={() => router.push("/signin")}
                className="text-sm font-medium hover:text-white/70 transition-colors"
              >
                Sign In
              </button>
            )}
          </div>
        </div>
      </div>
    </nav>
  );
}
