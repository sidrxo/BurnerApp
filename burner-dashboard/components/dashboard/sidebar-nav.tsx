"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";
import { CalendarDays, Tags, Users, LayoutDashboard } from "lucide-react";

const NAV_ITEMS = [
  { href: "/", label: "Overview", icon: LayoutDashboard },
  { href: "/events", label: "Events", icon: CalendarDays },
  { href: "/tags", label: "Tags", icon: Tags },
  { href: "/scanners", label: "Scanners", icon: Users }
];

export function SidebarNav() {
  const pathname = usePathname();

  return (
    <aside className="hidden min-h-screen w-60 flex-col border-r border-border bg-background/40 p-6 md:flex">
      <div className="mb-8 flex items-center gap-3">
        <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/20">
          <span className="text-xl font-semibold text-primary">B</span>
        </div>
        <div>
          <p className="text-sm font-semibold text-muted-foreground">Burner Cloud</p>
          <p className="text-lg font-bold tracking-tight">Admin Dashboard</p>
        </div>
      </div>
      <nav className="flex-1 space-y-1 text-sm">
        {NAV_ITEMS.map((item) => {
          const Icon = item.icon;
          const isActive = pathname === item.href;
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "flex items-center gap-3 rounded-lg px-3 py-2 transition-colors",
                isActive
                  ? "bg-primary/20 text-primary"
                  : "text-muted-foreground hover:bg-muted/40 hover:text-foreground"
              )}
            >
              <Icon className="h-4 w-4" />
              <span>{item.label}</span>
            </Link>
          );
        })}
      </nav>
      <div className="mt-10 rounded-lg border border-border bg-muted/10 p-4 text-xs text-muted-foreground">
        Manage events, scanners, and operational metadata synced with the latest cloud function schema.
      </div>
    </aside>
  );
}
