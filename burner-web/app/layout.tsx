"use client";

import type { Metadata } from "next";
import "./globals.css";
import { Toaster } from "sonner";
import { AuthProvider } from "@/components/useAuth";
import { PublicNav } from "@/components/public-nav";

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-background text-foreground">
        <AuthProvider>
          <div className="min-h-screen">
            <PublicNav />
            <main className="w-full pt-16">
              {children}
            </main>
          </div>
        </AuthProvider>
        <Toaster position="top-right" richColors />
      </body>
    </html>
  );
}
