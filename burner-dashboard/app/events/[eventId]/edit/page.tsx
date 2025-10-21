"use client";

import RequireAuth from "@/components/require-auth";
import { useRouter, useParams } from "next/navigation";
import { useEffect, useState } from "react";
import { doc, getDoc } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { useEventsData, Event } from "@/hooks/useEventsData";
import { EventForm, AccessDenied } from "@/components/events/EventsComponents";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ArrowLeft } from "lucide-react";

function EditEventPageContent() {
  const router = useRouter();
  const params = useParams();
  const eventId = params?.eventId as string;

  const {
    user,
    authLoading,
    venues,
    availableTags,
    setEvents
  } = useEventsData();

  const [event, setEvent] = useState<Event | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    if (!authLoading && user && eventId) {
      loadEvent();
    }
  }, [user, authLoading, eventId]);

  const loadEvent = async () => {
    if (!eventId) return;

    try {
      setLoading(true);
      const eventDoc = await getDoc(doc(db, "events", eventId));

      if (!eventDoc.exists()) {
        setError("Event not found");
        return;
      }

      const eventData = {
        id: eventDoc.id,
        ...eventDoc.data()
      } as Event;

      // Check if user has access to edit this event
      if (user?.role === "venueAdmin" && eventData.venueId !== user.venueId) {
        setError("You don't have access to edit this event");
        return;
      }

      setEvent(eventData);
    } catch (err) {
      console.error("Error loading event:", err);
      setError("Failed to load event");
    } finally {
      setLoading(false);
    }
  };

  // Show loading state while auth or event is loading
  if (authLoading || loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
      </div>
    );
  }

  // Show access denied for users without proper permissions
  if (!user) {
    return <AccessDenied user={null} />;
  }

  if (user.role !== "siteAdmin" && user.role !== "venueAdmin" && user.role !== "subAdmin") {
    return <AccessDenied user={user} />;
  }

  if (error) {
    return (
      <div className="container mx-auto p-6 space-y-6 max-w-4xl">
        <Card>
          <CardHeader>
            <CardTitle className="text-2xl text-destructive">Error</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <p>{error}</p>
            <Button onClick={() => router.push("/events")}>
              <ArrowLeft className="h-4 w-4 mr-2" />
              Back to Events
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  if (!event) {
    return null;
  }

  const handleSaved = (updatedEvent: Event) => {
    setEvents(prev => {
      const rest = prev.filter(x => x.id !== updatedEvent.id);
      return [updatedEvent, ...rest].sort((a,b)=>Number(!!b.isFeatured)-Number(!!a.isFeatured));
    });
    router.push("/events");
  };

  const handleClose = () => {
    router.push("/events");
  };

  return (
    <div className="container mx-auto p-6 space-y-6 max-w-4xl">
      <Button variant="ghost" onClick={handleClose} className="mb-2">
        <ArrowLeft className="h-4 w-4 mr-2" />
        Back to Events
      </Button>

      <Card>
        <CardHeader>
          <CardTitle className="text-2xl">Edit Event</CardTitle>
          <CardDescription>
            Update the event details below. All fields marked with * are required.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <EventForm
            existing={event}
            user={user}
            venues={venues}
            availableTags={availableTags}
            onSaved={handleSaved}
            onClose={handleClose}
          />
        </CardContent>
      </Card>
    </div>
  );
}

export default function EditEventPage() {
  return (
    <RequireAuth>
      <EditEventPageContent />
    </RequireAuth>
  );
}
