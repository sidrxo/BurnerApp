"use client";

import RequireAuth from "@/components/require-auth";
import { useAuth } from "@/components/useAuth";
import { useState, useEffect } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { AlertCircle, Calendar, RefreshCw, MapPin } from "lucide-react";
import { movePastEventsToFuture, getDebugInfo } from "@/lib/debug-utils";
import { toast } from "sonner";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";

function DebugToolsPageContent() {
  const { user, loading } = useAuth();
  const [debugInfo, setDebugInfo] = useState<any>(null);
  const [loadingInfo, setLoadingInfo] = useState(true);
  const [migrating, setMigrating] = useState(false);

  useEffect(() => {
    loadDebugInfo();
  }, []);

  const loadDebugInfo = async () => {
    setLoadingInfo(true);
    const info = await getDebugInfo();
    setDebugInfo(info);
    setLoadingInfo(false);
  };

  const handleMigratePastEvents = async () => {
    setMigrating(true);
    const result = await movePastEventsToFuture();

    if (result.success) {
      toast.success(`Successfully moved ${result.count} past events to the future!`);
      await loadDebugInfo(); // Refresh debug info
    } else {
      toast.error(result.error || "Failed to move past events");
    }

    setMigrating(false);
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

      {/* Event Migration Tool */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Calendar className="h-5 w-5" />
            Event Migration
          </CardTitle>
          <CardDescription>
            Move all past events to the future for testing and demo purposes
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="bg-muted p-4 rounded-lg">
            <h4 className="font-medium mb-2">What this does:</h4>
            <ul className="text-sm text-muted-foreground space-y-1 list-disc list-inside">
              <li>Finds all events with start times in the past</li>
              <li>Shifts them forward to be in the future (adds 1 week buffer)</li>
              <li>Maintains the duration if an end time is set</li>
              <li>Useful for refreshing demo/test environments</li>
            </ul>
          </div>

          <AlertDialog>
            <AlertDialogTrigger asChild>
              <Button
                variant="default"
                disabled={migrating || !debugInfo || debugInfo.pastEvents === 0}
                className="w-full"
              >
                {migrating ? (
                  <>
                    <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                    Migrating Events...
                  </>
                ) : (
                  <>
                    <Calendar className="h-4 w-4 mr-2" />
                    Move {debugInfo?.pastEvents || 0} Past Events to Future
                  </>
                )}
              </Button>
            </AlertDialogTrigger>
            <AlertDialogContent>
              <AlertDialogHeader>
                <AlertDialogTitle>Are you sure?</AlertDialogTitle>
                <AlertDialogDescription>
                  This will modify {debugInfo?.pastEvents || 0} events in the production database.
                  All past events will be shifted to future dates. This action cannot be undone.
                </AlertDialogDescription>
              </AlertDialogHeader>
              <AlertDialogFooter>
                <AlertDialogCancel>Cancel</AlertDialogCancel>
                <AlertDialogAction onClick={handleMigratePastEvents}>
                  Yes, Migrate Events
                </AlertDialogAction>
              </AlertDialogFooter>
            </AlertDialogContent>
          </AlertDialog>
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
