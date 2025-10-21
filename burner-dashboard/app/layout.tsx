"use client";

import "./globals.css";
import { AppNavbar } from "@/components/app-navbar";
import { Toaster } from "sonner";
import RequireAuth from "@/components/require-auth";
import { AuthProvider } from "@/components/useAuth";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-background text-foreground">
        <AuthProvider>
          <RequireAuth>
            <div className="min-h-screen">
              <AppNavbar />
              {/* Main content with left margin to account for fixed sidebar */}
              <main className="ml-64 p-6">
                <div className="max-w-[1400px] mx-auto w-full">
                  {children}
                </div>
              </main>
            </div>
          </RequireAuth>
        </AuthProvider>
        <Toaster position="top-right" richColors />
      </body>
    </html>
  );
}
