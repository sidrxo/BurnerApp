"use client";

import { useEffect, useState } from "react";
import { useRouter, useParams } from "next/navigation";
import { doc, getDoc, collection, query, where, getDocs } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { useAuth } from "@/components/useAuth";
import RequireAuth from "@/components/require-auth";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import {
  MapPin,
  Mail,
  Globe,
  Users,
  CalendarCheck,
  Shield,
  Ticket,
  TrendingUp,
  ArrowLeft
} from "lucide-react";
import Link from "next/link";

interface Venue {
  id: string;
  name: string;
  admins: string[];
  subAdmins: string[];
  address?: string;
  city?: string;
  capacity?: number;
  contactEmail?: string;
  website?: string;
  active?: boolean;
  eventCount?: number;
}

interface VenueStats {
  totalEvents: number;
  activeEvents: number;
  totalTicketsSold: number;
  totalRevenue: number;
}

function VenueDashboardContent() {
  const { user, loading: authLoading } = useAuth();
  const router = useRouter();
  const params = useParams();
  const venueId = params?.venueId as string;

  const [venue, setVenue] = useState<Venue | null>(null);
  const [stats, setStats] = useState<VenueStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    if (!authLoading && user && venueId) {
      loadVenueData();
    }
  }, [user, authLoading, venueId]);

  const loadVenueData = async () => {
    if (!venueId) return;

    try {
      setLoading(true);
      setError("");

      // Load venue details
      const venueDoc = await getDoc(doc(db, "venues", venueId));

      if (!venueDoc.exists()) {
        setError("Venue not found");
        setLoading(false);
        return;
      }

      const venueData = {
        id: venueDoc.id,
        ...venueDoc.data()
      } as Venue;

      // Check if user has access to this venue
      if (user?.role === "venueAdmin" && user.venueId !== venueId) {
        setError("You don't have access to this venue");
        setLoading(false);
        return;
      }

      setVenue(venueData);

      // Load venue statistics
      const eventsQuery = query(
        collection(db, "events"),
        where("venueId", "==", venueId)
      );
      const eventsSnapshot = await getDocs(eventsQuery);

      let totalTicketsSold = 0;
      let totalRevenue = 0;
      let activeEvents = 0;

      for (const eventDoc of eventsSnapshot.docs) {
        const eventData = eventDoc.data();

        if (eventData.status === "active" || eventData.status === "scheduled") {
          activeEvents++;
        }

        // Get tickets for this event
        const ticketsQuery = collection(db, "events", eventDoc.id, "tickets");
        const ticketsSnapshot = await getDocs(ticketsQuery);

        ticketsSnapshot.forEach((ticketDoc) => {
          const ticketData = ticketDoc.data();
          totalTicketsSold++;
          totalRevenue += ticketData.totalPrice || eventData.price || 0;
        });
      }

      setStats({
        totalEvents: eventsSnapshot.size,
        activeEvents,
        totalTicketsSold,
        totalRevenue
      });

    } catch (err) {
      console.error("Error loading venue dashboard:", err);
      setError("Failed to load venue data");
    } finally {
      setLoading(false);
    }
  };

  if (loading || authLoading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-center">
          <div className="text-4xl mb-4">⏳</div>
          <p className="text-muted-foreground">Loading venue dashboard...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[400px] text-center space-y-4">
        <div className="text-6xl mb-4">⚠️</div>
        <h2 className="text-2xl font-bold">{error}</h2>
        <Button onClick={() => router.push("/venues")}>
          <ArrowLeft className="h-4 w-4 mr-2" />
          Back to Venues
        </Button>
      </div>
    );
  }

  if (!venue) {
    return null;
  }

  const location = [venue.address, venue.city].filter(Boolean).join(", ");

  return (
    <div className="container mx-auto p-6 space-y-6 max-w-7xl">
      {/* Header */}
      <div className="space-y-2">
        <Button variant="ghost" onClick={() => router.push("/venues")} className="mb-2">
          <ArrowLeft className="h-4 w-4 mr-2" />
          Back to Venues
        </Button>
        <div className="flex items-start justify-between gap-4">
          <div>
            <h1 className="text-3xl font-bold">{venue.name}</h1>
            {location && (
              <p className="text-muted-foreground flex items-center gap-2 mt-1">
                <MapPin className="h-4 w-4" />
                {location}
              </p>
            )}
          </div>
          <Badge variant={venue.active === false ? "secondary" : "default"}>
            {venue.active === false ? "Inactive" : "Active"}
          </Badge>
        </div>
      </div>

      <Separator />

      {/* Stats Cards */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Events</CardTitle>
            <CalendarCheck className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats?.totalEvents ?? 0}</div>
            <p className="text-xs text-muted-foreground">
              {stats?.activeEvents ?? 0} active
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Tickets Sold</CardTitle>
            <Ticket className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats?.totalTicketsSold ?? 0}</div>
            <p className="text-xs text-muted-foreground">
              Across all events
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Revenue</CardTitle>
            <TrendingUp className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              £{((stats?.totalRevenue ?? 0) / 100).toFixed(2)}
            </div>
            <p className="text-xs text-muted-foreground">
              From ticket sales
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Capacity</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {venue.capacity ? venue.capacity.toLocaleString() : "—"}
            </div>
            <p className="text-xs text-muted-foreground">
              Maximum capacity
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Venue Details */}
      <div className="grid gap-6 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Venue Information</CardTitle>
            <CardDescription>Key details and contact information</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {venue.contactEmail && (
              <div className="flex items-center gap-3">
                <Mail className="h-5 w-5 text-muted-foreground" />
                <div>
                  <p className="text-sm font-medium">Contact Email</p>
                  <p className="text-sm text-muted-foreground">{venue.contactEmail}</p>
                </div>
              </div>
            )}

            {venue.website && (
              <div className="flex items-center gap-3">
                <Globe className="h-5 w-5 text-muted-foreground" />
                <div>
                  <p className="text-sm font-medium">Website</p>
                  <a
                    href={venue.website}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-sm text-primary hover:underline"
                  >
                    {venue.website}
                  </a>
                </div>
              </div>
            )}

            {location && (
              <div className="flex items-center gap-3">
                <MapPin className="h-5 w-5 text-muted-foreground" />
                <div>
                  <p className="text-sm font-medium">Location</p>
                  <p className="text-sm text-muted-foreground">{location}</p>
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Team Management</CardTitle>
            <CardDescription>Admins and access control</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center gap-3">
              <Shield className="h-5 w-5 text-primary" />
              <div>
                <p className="text-sm font-medium">Venue Admins</p>
                <p className="text-sm text-muted-foreground">
                  {venue.admins?.length ?? 0} admin{venue.admins?.length !== 1 ? "s" : ""}
                </p>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <Shield className="h-5 w-5 text-muted-foreground" />
              <div>
                <p className="text-sm font-medium">Sub-Admins</p>
                <p className="text-sm text-muted-foreground">
                  {venue.subAdmins?.length ?? 0} sub-admin{venue.subAdmins?.length !== 1 ? "s" : ""}
                </p>
              </div>
            </div>

            <Separator />

            <div className="space-y-2">
              <Button asChild className="w-full" variant="outline">
                <Link href="/events">
                  <CalendarCheck className="h-4 w-4 mr-2" />
                  View Events
                </Link>
              </Button>
              {user?.role === "siteAdmin" && (
                <Button asChild className="w-full" variant="outline">
                  <Link href="/admin-management">
                    <Users className="h-4 w-4 mr-2" />
                    Manage Team
                  </Link>
                </Button>
              )}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

export default function VenueDashboardPage() {
  return (
    <RequireAuth>
      <VenueDashboardContent />
    </RequireAuth>
  );
}
