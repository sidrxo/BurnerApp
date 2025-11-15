"use client";

import "../globals.css";
import { Toaster } from "sonner";
import { AuthProvider } from "@/components/useAuth";
import ErrorBoundary from "@/components/ErrorBoundary";
import { PublicNav } from "@/components/public-nav";

export default function PublicLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-background text-foreground">
        <ErrorBoundary
          fallbackTitle="Application Error"
          fallbackMessage="The application encountered an unexpected error. Please try refreshing the page."
        >
          <AuthProvider>
            <div className="min-h-screen">
              <PublicNav />
              <main className="w-full pt-16">
                {children}
              </main>
            </div>
          </AuthProvider>
        </ErrorBoundary>
        <Toaster position="top-right" richColors />
      </body>
    </html>
  );
}
