"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { Calendar, Home, Settings, Ticket, MapPin, Shield, User, Tag, LogOut } from "lucide-react";
import { cn } from "@/lib/utils";
import { useAuth } from "@/components/useAuth";
import { useEffect, useState } from "react";
import { doc, getDoc } from "firebase/firestore";
import { db, auth } from "@/lib/firebase";
import { signOut } from "firebase/auth";
import { toast } from "sonner";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Button } from "@/components/ui/button";

export function AppNavbar() {
  const pathname = usePathname();
  const router = useRouter();
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

  const handleSignOut = async () => {
    try {
      await signOut(auth);
      toast.success("Signed out successfully");
      router.replace("/login");
    } catch (e: any) {
      toast.error("Failed to sign out");
    }
  };

  let navigationItems = [
    { title: "Overview", url: "/overview", icon: Home },
    { title: "Events", url: "/events", icon: Calendar },
    { title: "Tickets", url: "/tickets", icon: Ticket },
  ];

  if (user?.role === "scanner") {
    navigationItems = [
      { title: "Tickets", url: "/tickets", icon: Ticket },
    ];
  } else {
    if (user && (user.role === "siteAdmin" || user.role === "venueAdmin")) {
      navigationItems.push({
        title: "Venues",
        url: "/venues",
        icon: MapPin,
      });
    }
  }

  return (
    <header className="fixed top-0 left-0 right-0 z-40 border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="flex h-16 items-center justify-between px-6">
        {/* Logo */}
        <Link href="/overview" className="flex items-center">
          <h1 className="text-xl font-bold tracking-tight">{venueName || "BURNER"}</h1>
        </Link>

        {/* Navigation */}
        <nav className="flex items-center space-x-1">
          {navigationItems.map((item) => {
            const Icon = item.icon;
            const isActive = pathname === item.url;
            return (
              <Link
                key={item.url}
                href={item.url}
                className={cn(
                  "flex items-center space-x-2 rounded-lg px-4 py-2 text-sm font-medium transition-all hover:bg-accent",
                  isActive
                    ? "bg-primary text-primary-foreground hover:bg-primary/90"
                    : "text-muted-foreground hover:text-foreground"
                )}
              >
                <Icon className="h-4 w-4" />
                <span>{item.title}</span>
              </Link>
            );
          })}
        </nav>

        {/* User Menu */}
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" size="sm" className="flex items-center space-x-2">
              <User className="h-4 w-4" />
              <span className="hidden sm:inline-block max-w-[150px] truncate">
                {user?.email || "User"}
              </span>
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="w-56">
            <DropdownMenuLabel>
              <div>
                <p className="text-sm font-medium">{user?.email || "User"}</p>
                <p className="text-xs text-muted-foreground capitalize">{user?.role || "user"}</p>
              </div>
            </DropdownMenuLabel>
            <DropdownMenuSeparator />
            <DropdownMenuItem asChild>
              <Link href="/account">
                <Settings className="mr-2 h-4 w-4" />
                Account Settings
              </Link>
            </DropdownMenuItem>
            {user?.role === "siteAdmin" && (
              <>
                <DropdownMenuItem asChild>
                  <Link href="/admin-management">
                    <Shield className="mr-2 h-4 w-4" />
                    Admin Management
                  </Link>
                </DropdownMenuItem>
                <DropdownMenuItem asChild>
                  <Link href="/tag-management">
                    <Tag className="mr-2 h-4 w-4" />
                    Tag Management
                  </Link>
                </DropdownMenuItem>
                <DropdownMenuSeparator />
                <DropdownMenuItem asChild>
                  <Link href="/debug">Debug Tools</Link>
                </DropdownMenuItem>
              </>
            )}
            <DropdownMenuSeparator />
            <DropdownMenuItem onClick={handleSignOut} className="cursor-pointer text-red-600 focus:text-red-600">
              <LogOut className="mr-2 h-4 w-4" />
              Sign Out
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </header>
  );
}