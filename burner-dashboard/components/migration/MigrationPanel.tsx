"use client";

import { useState } from "react";
import { httpsCallable } from "firebase/functions";
import { functions } from "@/lib/firebase";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { CheckCircle, XCircle, AlertTriangle, Loader2 } from "lucide-react";
import { toast } from "sonner";

type MigrationStatus = {
  venues?: {
    total: number;
    status: string;
    enhanced?: number;
  };
  events?: {
    total: number;
    withVenueId: number;
    withoutVenueId: number;
    status: string;
    enhanced?: number;
  };
  bookmarks?: {
    inRootCollection: number;
    status: string;
  };
  tickets?: {
    total: number;
    enhanced: number;
    status: string;
  };
  users?: {
    total: number;
    enhanced: number;
    status: string;
  };
  eventStats?: {
    total: number;
    status: string;
  };
};

export function MigrationPanel() {
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState<MigrationStatus | null>(null);
  const [phase4Status, setPhase4Status] = useState<MigrationStatus | null>(null);

  const checkStatus = async (functionName: string = 'verifyMigrationStatus') => {
    try {
      setLoading(true);
      const verifyStatus = httpsCallable(functions, functionName);
      const result = await verifyStatus();
      const data = result.data as any;
      
      if (data.success) {
        if (functionName === 'verifyPhase4Status') {
          setPhase4Status(data.status);
        } else {
          setStatus(data.status);
        }
      }
    } catch (error: any) {
      toast.error("Failed to check status: " + error.message);
    } finally {
      setLoading(false);
    }
  };

  const runMigration = async (migrationName: string, functionName: string) => {
    if (!confirm(`Are you sure you want to run: ${migrationName}?\n\nThis cannot be undone.`)) {
      return;
    }

    try {
      setLoading(true);
      const migrateFunction = httpsCallable(functions, functionName);
      const result = await migrateFunction();
      const data = result.data as any;
      
      if (data.success) {
        toast.success(data.message);
        // Refresh both statuses
        await checkStatus('verifyMigrationStatus');
        await checkStatus('verifyPhase4Status');
      } else {
        toast.error("Migration failed");
      }
    } catch (error: any) {
      console.error("Migration error:", error);
      toast.error("Migration error: " + (error.message || "Unknown error"));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Status Check Section */}
      <Card>
        <CardHeader>
          <CardTitle>Database Migration Control Panel</CardTitle>
          <CardDescription>
            Run these migrations in order. Each step is additive and won't break existing functionality.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
            <Button 
              onClick={() => checkStatus('verifyMigrationStatus')} 
              disabled={loading} 
              variant="outline" 
              className="w-full"
            >
              {loading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
              Check Phases 1-3 Status
            </Button>

            <Button 
              onClick={() => checkStatus('verifyPhase4Status')} 
              disabled={loading} 
              variant="outline" 
              className="w-full"
            >
              {loading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
              Check Phase 4 Status
            </Button>
          </div>

          {/* Phase 1-3 Status Display */}
          {status && (
            <div className="space-y-4 p-4 bg-muted rounded-lg">
              <h3 className="font-semibold text-lg">Phases 1-3 Status</h3>
              
              <div className="space-y-2">
                <h4 className="font-semibold">Venues Collection</h4>
                <div className="flex items-center gap-2">
                  {status.venues && status.venues.total > 0 ? (
                    <CheckCircle className="h-4 w-4 text-green-500" />
                  ) : (
                    <XCircle className="h-4 w-4 text-red-500" />
                  )}
                  <span>{status.venues?.status}</span>
                  <span className="text-muted-foreground">({status.venues?.total || 0} venues)</span>
                </div>
              </div>

              <div className="space-y-2">
                <h4 className="font-semibold">Events with venueId</h4>
                <div className="flex items-center gap-2">
                  {status.events && status.events.withoutVenueId === 0 ? (
                    <CheckCircle className="h-4 w-4 text-green-500" />
                  ) : (
                    <AlertTriangle className="h-4 w-4 text-yellow-500" />
                  )}
                  <span>{status.events?.status}</span>
                </div>
                <div className="text-sm text-muted-foreground">
                  {status.events?.withVenueId || 0} / {status.events?.total || 0} events migrated
                </div>
              </div>

              <div className="space-y-2">
                <h4 className="font-semibold">Bookmarks</h4>
                <div className="flex items-center gap-2">
                  {status.bookmarks && status.bookmarks.inRootCollection > 0 ? (
                    <CheckCircle className="h-4 w-4 text-green-500" />
                  ) : (
                    <XCircle className="h-4 w-4 text-red-500" />
                  )}
                  <span>{status.bookmarks?.status}</span>
                  <span className="text-muted-foreground">({status.bookmarks?.inRootCollection || 0} bookmarks)</span>
                </div>
              </div>
            </div>
          )}

          {/* Phase 4 Status Display */}
          {phase4Status && (
            <div className="space-y-4 p-4 bg-muted rounded-lg">
              <h3 className="font-semibold text-lg">Phase 4 Status</h3>
              
              <div className="space-y-2">
                <h4 className="font-semibold">Venues Enhanced</h4>
                <div className="flex items-center gap-2">
                  {phase4Status.venues && phase4Status.venues.enhanced === phase4Status.venues.total ? (
                    <CheckCircle className="h-4 w-4 text-green-500" />
                  ) : (
                    <AlertTriangle className="h-4 w-4 text-yellow-500" />
                  )}
                  <span>{phase4Status.venues?.status}</span>
                </div>
                <div className="text-sm text-muted-foreground">
                  {phase4Status.venues?.enhanced || 0} / {phase4Status.venues?.total || 0} venues enhanced
                </div>
              </div>

              <div className="space-y-2">
                <h4 className="font-semibold">Events Enhanced</h4>
                <div className="flex items-center gap-2">
                  {phase4Status.events && phase4Status.events.enhanced === phase4Status.events.total ? (
                    <CheckCircle className="h-4 w-4 text-green-500" />
                  ) : (
                    <AlertTriangle className="h-4 w-4 text-yellow-500" />
                  )}
                  <span>{phase4Status.events?.status}</span>
                </div>
                <div className="text-sm text-muted-foreground">
                  {phase4Status.events?.enhanced || 0} / {phase4Status.events?.total || 0} events enhanced
                </div>
              </div>

              <div className="space-y-2">
                <h4 className="font-semibold">Tickets Enhanced</h4>
                <div className="flex items-center gap-2">
                  {phase4Status.tickets && phase4Status.tickets.enhanced === phase4Status.tickets.total ? (
                    <CheckCircle className="h-4 w-4 text-green-500" />
                  ) : (
                    <AlertTriangle className="h-4 w-4 text-yellow-500" />
                  )}
                  <span>{phase4Status.tickets?.status}</span>
                </div>
                <div className="text-sm text-muted-foreground">
                  {phase4Status.tickets?.enhanced || 0} / {phase4Status.tickets?.total || 0} tickets enhanced
                </div>
              </div>

              <div className="space-y-2">
                <h4 className="font-semibold">Users Enhanced</h4>
                <div className="flex items-center gap-2">
                  {phase4Status.users && phase4Status.users.enhanced === phase4Status.users.total ? (
                    <CheckCircle className="h-4 w-4 text-green-500" />
                  ) : (
                    <AlertTriangle className="h-4 w-4 text-yellow-500" />
                  )}
                  <span>{phase4Status.users?.status}</span>
                </div>
                <div className="text-sm text-muted-foreground">
                  {phase4Status.users?.enhanced || 0} / {phase4Status.users?.total || 0} users enhanced
                </div>
              </div>

              <div className="space-y-2">
                <h4 className="font-semibold">Event Stats</h4>
                <div className="flex items-center gap-2">
                  {phase4Status.eventStats && phase4Status.eventStats.total > 0 ? (
                    <CheckCircle className="h-4 w-4 text-green-500" />
                  ) : (
                    <XCircle className="h-4 w-4 text-red-500" />
                  )}
                  <span>{phase4Status.eventStats?.status}</span>
                  <span className="text-muted-foreground">({phase4Status.eventStats?.total || 0} stats)</span>
                </div>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Phase 1: Create Venues */}
      <Card>
        <CardHeader>
          <CardTitle>Phase 1: Create Venues Collection</CardTitle>
          <CardDescription>
            Extracts unique venues from events and creates venue documents. Safe to run multiple times.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Button 
            onClick={() => runMigration("Create Venues", "migrateCreateVenues")}
            disabled={loading}
            className="w-full"
          >
            {loading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
            Run Phase 1
          </Button>
        </CardContent>
      </Card>

      {/* Phase 2: Add Venue IDs */}
      <Card>
        <CardHeader>
          <CardTitle>Phase 2: Add Venue IDs to Events</CardTitle>
          <CardDescription>
            Adds venueId field to all events. Keeps old venue string for backwards compatibility.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Button 
            onClick={() => runMigration("Add Venue IDs", "migrateAddVenueIdsToEvents")}
            disabled={loading || !status?.venues?.total}
            className="w-full"
          >
            {loading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
            Run Phase 2
          </Button>
          {!status?.venues?.total && (
            <Alert className="mt-2">
              <AlertDescription>Run Phase 1 first</AlertDescription>
            </Alert>
          )}
        </CardContent>
      </Card>

      {/* Phase 3: Migrate Bookmarks */}
      <Card>
        <CardHeader>
          <CardTitle>Phase 3: Migrate Bookmarks</CardTitle>
          <CardDescription>
            Copies bookmarks to root collection. Old subcollections remain for backwards compatibility.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Button 
            onClick={() => runMigration("Migrate Bookmarks", "migrateBookmarksToRoot")}
            disabled={loading}
            className="w-full"
          >
            {loading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
            Run Phase 3
          </Button>
        </CardContent>
      </Card>

      {/* Divider */}
      <div className="border-t pt-6">
        <h2 className="text-2xl font-bold mb-4">Phase 4: Enhance Collections</h2>
        <p className="text-muted-foreground mb-6">
          These migrations add additional fields to existing collections to match the optimized structure.
        </p>
      </div>

      {/* Phase 4A: Enhance Venues */}
      <Card>
        <CardHeader>
          <CardTitle>Phase 4A: Enhance Venues</CardTitle>
          <CardDescription>
            Adds address, city, capacity, contact info, and other fields to venues.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Button 
            onClick={() => runMigration("Enhance Venues", "migrateEnhanceVenues")}
            disabled={loading || !status?.venues?.total}
            className="w-full"
          >
            {loading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
            Run Phase 4A
          </Button>
          {!status?.venues?.total && (
            <Alert className="mt-2">
              <AlertDescription>Complete Phases 1-3 first</AlertDescription>
            </Alert>
          )}
        </CardContent>
      </Card>

      {/* Phase 4B: Enhance Events */}
      <Card>
        <CardHeader>
          <CardTitle>Phase 4B: Enhance Events</CardTitle>
          <CardDescription>
            Adds status, startTime, endTime, category, tags, and organizerId to events.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Button 
            onClick={() => runMigration("Enhance Events", "migrateEnhanceEvents")}
            disabled={loading || !status?.events?.total}
            className="w-full"
          >
            {loading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
            Run Phase 4B
          </Button>
          {!status?.events?.total && (
            <Alert className="mt-2">
              <AlertDescription>Complete Phases 1-3 first</AlertDescription>
            </Alert>
          )}
        </CardContent>
      </Card>

      {/* Phase 4C: Enhance Tickets */}
      <Card>
        <CardHeader>
          <CardTitle>Phase 4C: Enhance Tickets</CardTitle>
          <CardDescription>
            Adds status, qrCodeSignature, refund fields, and transfer tracking to tickets.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Button 
            onClick={() => runMigration("Enhance Tickets", "migrateEnhanceTickets")}
            disabled={loading}
            className="w-full"
          >
            {loading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
            Run Phase 4C
          </Button>
        </CardContent>
      </Card>

      {/* Phase 4D: Enhance Users */}
      <Card>
        <CardHeader>
          <CardTitle>Phase 4D: Enhance Users</CardTitle>
          <CardDescription>
            Adds phoneNumber, preferences, stripeCustomerId, and profileImageUrl to users.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Button 
            onClick={() => runMigration("Enhance Users", "migrateEnhanceUsers")}
            disabled={loading}
            className="w-full"
          >
            {loading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
            Run Phase 4D
          </Button>
        </CardContent>
      </Card>

      {/* Phase 4E: Create Event Stats */}
      <Card>
        <CardHeader>
          <CardTitle>Phase 4E: Create Event Stats</CardTitle>
          <CardDescription>
            Creates denormalized eventStats collection for fast analytics queries. This may take several minutes.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Button 
            onClick={() => runMigration("Create Event Stats", "migrateCreateEventStats")}
            disabled={loading || !status?.events?.total}
            className="w-full"
          >
            {loading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
            Run Phase 4E
          </Button>
          {!status?.events?.total && (
            <Alert className="mt-2">
              <AlertDescription>Complete Phases 1-3 first</AlertDescription>
            </Alert>
          )}
        </CardContent>
      </Card>

      {/* Warning Section */}
      <Alert>
        <AlertTriangle className="h-4 w-4" />
        <AlertDescription>
          <strong>Important:</strong> Run migrations during low-traffic periods. Each phase is safe and non-destructive, 
          but Phase 4E may take several minutes for large datasets.
        </AlertDescription>
      </Alert>
    </div>
  );
}