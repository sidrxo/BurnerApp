"use client";

import { useMemo } from "react";
import { useEvents } from "@/hooks/use-events";
import { useScanners } from "@/hooks/use-scanners";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { CalendarClock, Ticket, Users } from "lucide-react";
import { format } from "date-fns";

export default function DashboardPage() {
  const { events } = useEvents();
  const { scanners } = useScanners();

  const metrics = useMemo(() => {
    const upcoming = events.filter((event) => {
      if (!event.startTime) return true;
      return event.startTime.getTime() >= Date.now();
    });
    const activeScanners = scanners.filter((scanner) => scanner.active).length;
    const ticketCapacity = events.reduce(
      (acc, event) => acc + Math.max(event.maxTickets - event.ticketsSold, 0),
      0
    );

    return {
      upcomingCount: upcoming.length,
      capacityRemaining: ticketCapacity,
      activeScanners
    };
  }, [events, scanners]);

  const nextEvent = useMemo(() => {
    return events
      .filter((event) => event.startTime)
      .sort((a, b) => (a.startTime?.getTime() ?? 0) - (b.startTime?.getTime() ?? 0))[0];
  }, [events]);

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-semibold tracking-tight">Welcome back, operator</h2>
        <p className="text-sm text-muted-foreground">
          Monitor venue capacity, upcoming events, and scanning resources in real time.
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <Card className="bg-card/40">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Upcoming events</CardTitle>
            <CalendarClock className="h-4 w-4 text-primary" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{metrics.upcomingCount}</div>
            <p className="text-xs text-muted-foreground">Synced from Firestore events collection</p>
          </CardContent>
        </Card>

        <Card className="bg-card/40">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Active scanners</CardTitle>
            <Users className="h-4 w-4 text-primary" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{metrics.activeScanners}</div>
            <p className="text-xs text-muted-foreground">Accounts that can verify tickets tonight</p>
          </CardContent>
        </Card>

        <Card className="bg-card/40">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Available ticket inventory</CardTitle>
            <Ticket className="h-4 w-4 text-primary" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{metrics.capacityRemaining}</div>
            <p className="text-xs text-muted-foreground">Remaining seats across all active events</p>
          </CardContent>
        </Card>
      </div>

      {nextEvent ? (
        <Card className="border-primary/50 bg-gradient-to-br from-primary/10 via-background to-background">
          <CardHeader className="flex flex-col items-start space-y-3 md:flex-row md:items-center md:justify-between">
            <div>
              <CardTitle className="text-xl">Next on deck: {nextEvent.name}</CardTitle>
              <p className="text-sm text-muted-foreground">
                {nextEvent.venueName} • {nextEvent.startTime ? format(nextEvent.startTime, "PPP p") : "TBA"}
              </p>
            </div>
            {nextEvent.tagName ? <Badge>{nextEvent.tagName}</Badge> : null}
          </CardHeader>
          <CardContent className="grid gap-4 md:grid-cols-3">
            <div>
              <p className="text-xs uppercase tracking-wide text-muted-foreground">Tickets sold</p>
              <p className="text-lg font-semibold">{nextEvent.ticketsSold} / {nextEvent.maxTickets}</p>
            </div>
            <div>
              <p className="text-xs uppercase tracking-wide text-muted-foreground">Doors close</p>
              <p className="text-lg font-semibold">
                {nextEvent.endTime ? format(nextEvent.endTime, "PPP p") : "Set end time in event editor"}
              </p>
            </div>
            <div>
              <p className="text-xs uppercase tracking-wide text-muted-foreground">Status</p>
              <p className="text-lg font-semibold capitalize">{nextEvent.status ?? "active"}</p>
            </div>
          </CardContent>
        </Card>
      ) : null}
    </div>
  );
}
