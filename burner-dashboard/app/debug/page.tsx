"use client";

import RequireAuth from "@/components/require-auth";
import { useAuth } from "@/components/useAuth";
import { useState, useEffect } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { AlertCircle, RefreshCw, Calendar, PlayCircle } from "lucide-react";
import { getDebugInfo, movePastEventsToFuture, simulateEventStartingSoon } from "@/lib/debug-utils";
import { toast } from "sonner";

function DebugToolsPageContent() {
  const { user, loading } = useAuth();
  const [debugInfo, setDebugInfo] = useState<any>(null);
  const [loadingInfo, setLoadingInfo] = useState(true);
  const [movingEvents, setMovingEvents] = useState(false);
  const [simulatingEvent, setSimulatingEvent] = useState(false);

  useEffect(() => {
    loadDebugInfo();
  }, []);

  const loadDebugInfo = async () => {
    setLoadingInfo(true);
    const info = await getDebugInfo();
    setDebugInfo(info);
    setLoadingInfo(false);
  };

  const handleMoveEventsToFuture = async () => {
    setMovingEvents(true);
    try {
      const result = await movePastEventsToFuture();
      if (result.success) {
        toast.success(`Moved ${result.count} past event${result.count !== 1 ? 's' : ''} to the future`);
        // Reload debug info to show updated stats
        await loadDebugInfo();
      } else {
        toast.error("Failed to move events to the future");
      }
    } catch (error) {
      toast.error("An unexpected error occurred");
    } finally {
      setMovingEvents(false);
    }
  };

  const handleSimulateEvent = async () => {
    setSimulatingEvent(true);
    try {
      const result = await simulateEventStartingSoon();
      if (result.success) {
        toast.success(`"${result.eventName}" will start in 5 minutes`);
        // Reload debug info to show updated stats
        await loadDebugInfo();
      } else {
        toast.error(result.error || "Failed to simulate event");
      }
    } catch (error) {
      toast.error("An unexpected error occurred");
    } finally {
      setSimulatingEvent(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
      </div>
    );
  }

  // Only site admins can access
  if (!user || user.role !== "siteAdmin") {
    return (
      <Card className="max-w-md mx-auto mt-10">
        <CardHeader>
          <CardTitle className="text-center">Access Denied</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-center text-muted-foreground">
            Only site administrators can access debug tools.
          </p>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-6 max-w-4xl mx-auto">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Debug Tools</h1>
        <p className="text-muted-foreground mt-1">
          Development and testing utilities for site administrators
        </p>
      </div>

      {/* Warning Banner */}
      <div className="bg-yellow-500/10 border border-yellow-500/20 rounded-lg p-4 flex items-start gap-3">
        <AlertCircle className="h-5 w-5 text-yellow-600 mt-0.5" />
        <div>
          <h3 className="font-semibold text-yellow-900 dark:text-yellow-100">
            Warning: Production Database
          </h3>
          <p className="text-sm text-yellow-800 dark:text-yellow-200 mt-1">
            These tools modify production data. Use with caution and only for testing/demo purposes.
          </p>
        </div>
      </div>

      {/* Database Statistics */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>Database Statistics</CardTitle>
              <CardDescription>Current state of the database</CardDescription>
            </div>
            <Button
              variant="outline"
              size="sm"
              onClick={loadDebugInfo}
              disabled={loadingInfo}
            >
              <RefreshCw className={`h-4 w-4 mr-2 ${loadingInfo ? "animate-spin" : ""}`} />
              Refresh
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {loadingInfo ? (
            <div className="flex justify-center py-8">
              <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-primary"></div>
            </div>
          ) : debugInfo ? (
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div className="p-4 bg-muted rounded-lg">
                <div className="text-sm text-muted-foreground mb-1">Total Events</div>
                <div className="text-2xl font-bold">{debugInfo.totalEvents}</div>
              </div>
              <div className="p-4 bg-muted rounded-lg">
                <div className="text-sm text-muted-foreground mb-1">Past Events</div>
                <div className="text-2xl font-bold text-orange-600">{debugInfo.pastEvents}</div>
              </div>
              <div className="p-4 bg-muted rounded-lg">
                <div className="text-sm text-muted-foreground mb-1">Future Events</div>
                <div className="text-2xl font-bold text-green-600">{debugInfo.futureEvents}</div>
              </div>
              <div className="p-4 bg-muted rounded-lg">
                <div className="text-sm text-muted-foreground mb-1">Total Venues</div>
                <div className="text-2xl font-bold">{debugInfo.totalVenues}</div>
              </div>
            </div>
          ) : (
            <p className="text-muted-foreground text-center py-8">
              Failed to load debug information
            </p>
          )}
        </CardContent>
      </Card>

      {/* Event Management Tools */}
      <Card>
        <CardHeader>
          <CardTitle>Event Management</CardTitle>
          <CardDescription>Tools for managing event data</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-start gap-4 p-4 border rounded-lg">
            <div className="p-2 bg-primary/10 rounded-lg">
              <Calendar className="h-5 w-5 text-primary" />
            </div>
            <div className="flex-1">
              <h3 className="font-semibold mb-1">Move All Events to Future</h3>
              <p className="text-sm text-muted-foreground mb-3">
                Moves all past events to the future (current day + 7 days).
                Useful for demo purposes when event data becomes outdated.
              </p>
              {debugInfo && debugInfo.pastEvents > 0 && (
                <Badge variant="outline" className="mb-3">
                  {debugInfo.pastEvents} past event{debugInfo.pastEvents !== 1 ? 's' : ''} will be moved
                </Badge>
              )}
              <Button
                onClick={handleMoveEventsToFuture}
                disabled={movingEvents || (debugInfo && debugInfo.pastEvents === 0)}
                variant="default"
              >
                {movingEvents ? (
                  <>
                    <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                    Moving Events...
                  </>
                ) : (
                  <>
                    <Calendar className="h-4 w-4 mr-2" />
                    Move Events to Future
                  </>
                )}
              </Button>
            </div>
          </div>

          <div className="flex items-start gap-4 p-4 border rounded-lg">
            <div className="p-2 bg-primary/10 rounded-lg">
              <PlayCircle className="h-5 w-5 text-primary" />
            </div>
            <div className="flex-1">
              <h3 className="font-semibold mb-1">Simulate Event Starting Soon</h3>
              <p className="text-sm text-muted-foreground mb-3">
                Sets the soonest event to start in 5 minutes and end 10 minutes later.
                Useful for testing event notifications and real-time features.
              </p>
              <Button
                onClick={handleSimulateEvent}
                disabled={simulatingEvent || (debugInfo && debugInfo.totalEvents === 0)}
                variant="default"
              >
                {simulatingEvent ? (
                  <>
                    <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                    Simulating Event...
                  </>
                ) : (
                  <>
                    <PlayCircle className="h-4 w-4 mr-2" />
                    Simulate Event
                  </>
                )}
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

    </div>
  );
}

export default function DebugToolsPage() {
  return (
    <RequireAuth>
      <DebugToolsPageContent />
    </RequireAuth>
  );
}
