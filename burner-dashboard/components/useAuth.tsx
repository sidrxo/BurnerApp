"use client";

import { useEffect, useState, useRef, createContext, useContext, ReactNode } from "react";
import { supabase } from "@/lib/supabase";
import type { User as SupabaseUser } from "@supabase/supabase-js";

type Role = "siteAdmin" | "venueAdmin" | "subAdmin" | "scanner" | "organiser" | "user";

type AppUser = {
  uid: string;
  email: string | null;
  role: Role;
  venueId?: string | null;
  active: boolean;
};

type AuthContextType = {
  user: AppUser | null;
  loading: boolean;
  refreshUser: () => Promise<void>;
};

const AuthContext = createContext<AuthContextType>({
  user: null,
  loading: true,
  refreshUser: async () => {}
});

// Helper function to validate role type
function isValidRole(role: any): role is Role {
  return typeof role === 'string' &&
         ['siteAdmin', 'venueAdmin', 'subAdmin', 'scanner', 'organiser', 'user'].includes(role);
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AppUser | null>(null);
  const [loading, setLoading] = useState(true);
  const userRef = useRef<AppUser | null>(null);
  const isInitializedRef = useRef(false);

  const getUserProfile = async (supabaseUser: SupabaseUser): Promise<AppUser> => {
    try {
      // Query unified users table
      const { data: userData, error: userError } = await supabase
        .from('users')
        .select('id, email, role, venue_id, active')
        .eq('id', supabaseUser.id)
        .single();

      if (userData && !userError) {
        // Check if user is active
        if (userData.active === false) {
          await supabase.auth.signOut();
          return {
            uid: supabaseUser.id,
            email: supabaseUser.email ?? null,
            role: "user",
            venueId: null,
            active: false,
          };
        }

        return {
          uid: userData.id,
          email: userData.email,
          role: isValidRole(userData.role) ? userData.role : "user",
          venueId: userData.venue_id,
          active: userData.active !== false,
        };
      }

      // If user not found in database, return basic profile
      return {
        uid: supabaseUser.id,
        email: supabaseUser.email ?? null,
        role: "user",
        venueId: null,
        active: true,
      };
    } catch (error: any) {
      console.error("Error getting user profile:", error);

      // Fallback to basic user info
      return {
        uid: supabaseUser.id,
        email: supabaseUser.email ?? null,
        role: "user",
        venueId: null,
        active: true,
      };
    }
  };

  const updateUser = (newUser: AppUser | null) => {
    userRef.current = newUser;
    setUser(newUser);
  };

  const refreshUser = async () => {
    try {
      const { data: { user: supabaseUser } } = await supabase.auth.getUser();

      if (supabaseUser) {
        const appUser = await getUserProfile(supabaseUser);
        updateUser(appUser);
      } else {
        updateUser(null);
      }
    } catch (error) {
      console.error("Error refreshing user:", error);
      updateUser(null);
    }
  };

  useEffect(() => {
    // Check active session on mount
    const initializeAuth = async () => {
      try {
        const { data: { session } } = await supabase.auth.getSession();

        if (session?.user) {
          const appUser = await getUserProfile(session.user);
          updateUser(appUser);
        } else {
          updateUser(null);
        }
      } catch (error) {
        console.error("Error initializing auth:", error);
        updateUser(null);
      } finally {
        setLoading(false);
        isInitializedRef.current = true;
      }
    };

    // Add timeout fallback to ensure loading doesn't stay true forever
    const initTimeout = setTimeout(() => {
      if (loading && !isInitializedRef.current) {
        console.warn("Auth initialization timed out - check server connection");
        setLoading(false);
        isInitializedRef.current = true;
        updateUser(null);
      }
    }, 10000);

    initializeAuth().finally(() => clearTimeout(initTimeout));

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        // Skip reloading for SIGNED_IN and TOKEN_REFRESHED events when user is already authenticated
        // This prevents loading spinners when navigating between pages or when tab regains focus
        const currentUser = userRef.current;
        if ((event === 'SIGNED_IN' || event === 'TOKEN_REFRESHED') &&
            currentUser !== null &&
            session?.user?.id === currentUser.uid &&
            isInitializedRef.current) {
          return;
        }

        // Only show loading for meaningful auth state changes
        const shouldShowLoading = (event !== 'SIGNED_IN' && event !== 'TOKEN_REFRESHED') || currentUser === null;

        if (session?.user) {
          if (shouldShowLoading) {
            setLoading(true);
          }

          // Set a timeout to prevent infinite loading
          const loadingTimeout = setTimeout(() => {
            if (loading || shouldShowLoading) {
              console.warn("Auth state change timed out - check server connection");
              setLoading(false);
            }
          }, 10000);

          try {
            // Retry logic with exponential backoff for database sync
            let appUser: AppUser | null = null;
            let retries = 0;
            const maxRetries = 3;

            while (retries < maxRetries && !appUser) {
              try {
                if (retries > 0) {
                  const delay = Math.min(100 * Math.pow(2, retries - 1), 1600);
                  await new Promise(resolve => setTimeout(resolve, delay));
                }

                appUser = await getUserProfile(session.user);

                // If we got a valid user, break out
                if (appUser) {
                  break;
                }

                retries++;
              } catch (error) {
                console.error(`Profile fetch attempt ${retries + 1} failed:`, error);
                retries++;
                if (retries >= maxRetries) {
                  throw error;
                }
              }
            }

            updateUser(appUser);
          } catch (error) {
            console.error("Error processing authenticated user:", error);
            updateUser(null);
          } finally {
            clearTimeout(loadingTimeout);
            if (shouldShowLoading) {
              setLoading(false);
            }
          }
        } else {
          updateUser(null);
          setLoading(false);
        }
      }
    );

    return () => {
      subscription.unsubscribe();
    };
  }, []);

  return (
    <AuthContext.Provider value={{ user, loading, refreshUser }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}
