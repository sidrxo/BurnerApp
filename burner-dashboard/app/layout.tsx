"use client";

import "./globals.css";
import { AppNavbar } from "@/components/app-navbar";
import { Toaster } from "sonner";
import RequireAuth from "@/components/require-auth";
import { AuthProvider } from "@/components/useAuth";
import ErrorBoundary from "@/components/ErrorBoundary";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-background text-foreground">
        <ErrorBoundary fallbackTitle="Application Error" fallbackMessage="The application encountered an unexpected error. Please try refreshing the page.">
          <AuthProvider>
            <ErrorBoundary fallbackTitle="Authentication Error" fallbackMessage="There was a problem with authentication. Please try logging in again.">
              <RequireAuth>
                <ErrorBoundary fallbackTitle="Page Error" fallbackMessage="This page encountered an error. Please try navigating to a different page or refresh.">
                  <div className="min-h-screen">
                    <AppNavbar />
                    {/* Main content with left margin to account for fixed sidebar */}
                    <main className="ml-64 p-6">
                      <div className="max-w-[1400px] mx-auto w-full">
                        {children}
                      </div>
                    </main>
                  </div>
                </ErrorBoundary>
              </RequireAuth>
            </ErrorBoundary>
          </AuthProvider>
        </ErrorBoundary>
        <Toaster position="top-right" richColors />
      </body>
    </html>
  );
}
