"use client";

import { Bell, LogOut } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useMemo } from "react";

export function TopBar() {
  const today = useMemo(() => new Date().toLocaleDateString(undefined, {
    month: "long",
    day: "numeric",
    year: "numeric"
  }), []);

  return (
    <header className="sticky top-0 z-40 flex h-16 items-center justify-between border-b border-border bg-background/80 px-6 backdrop-blur">
      <div>
        <p className="text-xs uppercase tracking-wide text-muted-foreground">Synced {today}</p>
        <h1 className="text-lg font-semibold">Burner Cloud Operations</h1>
      </div>
      <div className="flex items-center gap-2">
        <Button variant="ghost" size="icon" className="text-muted-foreground">
          <Bell className="h-4 w-4" />
        </Button>
        <Button variant="ghost" size="icon" className="text-muted-foreground">
          <LogOut className="h-4 w-4" />
        </Button>
      </div>
    </header>
  );
}
