"use client";

import RequireAuth from "@/components/require-auth";
import { useRouter } from "next/navigation";
import { useEventsData, Event } from "@/hooks/useEventsData";
import { EventForm, AccessDenied } from "@/components/events/EventsComponents";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ArrowLeft } from "lucide-react";

function CreateEventPageContent() {
  const router = useRouter();
  const {
    user,
    authLoading,
    venues,
    availableTags,
    setEvents
  } = useEventsData();

  // Show loading state while auth is loading
  if (authLoading) {
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

  const handleSaved = (event: Event) => {
    setEvents(prev => {
      const rest = prev.filter(x => x.id !== event.id);
      return [event, ...rest].sort((a,b)=>Number(!!b.isFeatured)-Number(!!a.isFeatured));
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
          <CardTitle className="text-2xl">Create New Event</CardTitle>
          <CardDescription>
            Fill in the details below to create a new event. All fields marked with * are required.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <EventForm
            existing={null}
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

export default function CreateEventPage() {
  return (
    <RequireAuth>
      <CreateEventPageContent />
    </RequireAuth>
  );
}
