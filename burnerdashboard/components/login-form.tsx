"use client";

import { useState } from "react";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { supabase } from "@/lib/supabase";
import { toast } from "sonner";
import { useRouter } from "next/navigation";
import { AlertCircle } from "lucide-react";

export function LoginForm({ className, ...props }: React.ComponentProps<"div">) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [isDeactivated, setIsDeactivated] = useState(false);
  const router = useRouter();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setIsDeactivated(false);

    try {
      // Sign in with Supabase
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (error) {
        throw error;
      }

      if (data.user) {
        // Check if user is active
        let isActive = true;

        try {
          // First check admins collection
          const { data: adminData } = await supabase
            .from('admins')
            .select('active')
            .eq('id', data.user.id)
            .single();

          if (adminData) {
            isActive = adminData.active !== false;
          } else {
            // Check users collection
            const { data: userData } = await supabase
              .from('users')
              .select('active')
              .eq('id', data.user.id)
              .single();

            if (userData) {
              isActive = userData.active !== false;
            }
          }
        } catch (docError) {
          console.error("Error checking user active status:", docError);
          // Continue with login if we can't check the status
        }

        if (!isActive) {
          // Sign out the user immediately
          await supabase.auth.signOut();
          setIsDeactivated(true);
          toast.error("Your account has been deactivated. Please contact support.");
        } else {
          router.push("/overview");
        }
      }
    } catch (error: any) {
      console.error("Login error:", error);

      // Handle Supabase-specific error messages
      if (error.message?.includes('Invalid login credentials')) {
        toast.error("Invalid email or password");
      } else if (error.message?.includes('Email not confirmed')) {
        toast.error("Please verify your email address");
      } else if (error.message?.includes('Email not valid')) {
        toast.error("Please enter a valid email address");
      } else {
        toast.error(error.message || "Login failed");
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className={cn("flex flex-col gap-6", className)} {...props}>
      <Card>
        <CardHeader>
          <CardTitle>Login to your account</CardTitle>
          <CardDescription>
            Enter your email and password below
          </CardDescription>
        </CardHeader>
        <CardContent>
          {isDeactivated && (
            <Alert variant="destructive" className="mb-6">
              <AlertCircle className="h-4 w-4" />
              <AlertDescription>
                Your account has been deactivated. Please contact support for assistance.
              </AlertDescription>
            </Alert>
          )}
          <form onSubmit={handleSubmit}>
            <div className="flex flex-col gap-6">
              <div className="grid gap-3">
                <Label htmlFor="email">Email</Label>
                <Input
                  id="email"
                  type="email"
                  placeholder="m@example.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                />
              </div>
              <div className="grid gap-3">
                <Label htmlFor="password">Password</Label>
                <Input
                  id="password"
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                />
              </div>
              <div className="flex flex-col gap-3">
                <Button type="submit" className="w-full" disabled={loading}>
                  {loading ? "Logging in..." : "Login"}
                </Button>
              </div>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
