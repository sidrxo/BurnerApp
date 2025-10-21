"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Calendar, Home, Settings, Ticket, MapPin, Shield } from "lucide-react";
import { cn } from "@/lib/utils";
import { useAuth } from "@/components/useAuth";
import { useEffect, useState } from "react";
import { doc, getDoc } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { Separator } from "@/components/ui/separator";

export function AppNavbar() {
  const pathname = usePathname();
  const { user } = useAuth();
  const [venueName, setVenueName] = useState<string>("");

  // Fetch venue name when user changes
  useEffect(() => {
    const fetchVenueName = async () => {
      if (user?.venueId) {
        try {
          const venueDoc = await getDoc(doc(db, "venues", user.venueId));
          if (venueDoc.exists()) {
            setVenueName(venueDoc.data().name);
          }
        } catch (error) {
          console.error("Error fetching venue name:", error);
          setVenueName("");
        }
      } else if (user?.role === "siteAdmin") {
        setVenueName("BURNER");
      } else {
        setVenueName("");
      }
    };

    fetchVenueName();
  }, [user]);

  let navigationItems = [
    { title: "Overview", url: "/overview", icon: Home },
    { title: "Events", url: "/events", icon: Calendar },
    { title: "Tickets", url: "/tickets", icon: Ticket },
    { title: "Account", url: "/account", icon: Settings },
  ];

  if (user?.role === "scanner") {
    navigationItems = [
      { title: "Tickets", url: "/tickets", icon: Ticket },
      { title: "Account", url: "/account", icon: Settings },
    ];
  } else {
    if (user && (user.role === "siteAdmin" || user.role === "venueAdmin")) {
      navigationItems.splice(3, 0, {
        title: "Venues",
        url: "/venues",
        icon: MapPin,
      });
    }

    if (user && user.role === "siteAdmin") {
      navigationItems.splice(4, 0, {
        title: "Admin Management",
        url: "/admin-management",
        icon: Shield,
      });
    }
  }

  return (
    <aside className="fixed left-0 top-0 z-40 h-screen w-64 border-r bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="flex h-full flex-col">
        {/* Logo/Header */}
        <div className="flex h-16 items-center border-b px-6">
          <h1 className="text-xl font-bold tracking-tight">{venueName || "BURNER"}</h1>
        </div>

        {/* Navigation */}
        <nav className="flex-1 space-y-1 p-4 overflow-y-auto">
          {navigationItems.map((item) => {
            const Icon = item.icon;
            const isActive = pathname === item.url;
            return (
              <Link
                key={item.url}
                href={item.url}
                className={cn(
                  "flex items-center space-x-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-all hover:bg-accent",
                  isActive
                    ? "bg-primary text-primary-foreground hover:bg-primary/90"
                    : "text-muted-foreground hover:text-foreground"
                )}
              >
                <Icon className="h-5 w-5" />
                <span>{item.title}</span>
              </Link>
            );
          })}
        </nav>

        {/* Footer with user info */}
        <div className="border-t p-4">
          <div className="rounded-lg bg-muted/50 p-3">
            <p className="text-xs font-medium text-muted-foreground">Signed in as</p>
            <p className="mt-1 text-sm font-semibold truncate">{user?.email || "User"}</p>
            <p className="mt-0.5 text-xs text-muted-foreground capitalize">{user?.role || "user"}</p>
          </div>
        </div>
      </div>
    </aside>
  );
}