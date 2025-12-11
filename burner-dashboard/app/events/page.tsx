"use client";

import RequireAuth from "@/components/require-auth";
import ErrorBoundary from "@/components/ErrorBoundary";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { useEventsData, Event } from "@/hooks/useEventsData";
import {
  EventSkeleton,
  AccessDenied,
  SearchAndStats,
  EmptyEventsState,
  EventCard
} from "@/components/events/EventsComponents";
import { Button } from "@/components/ui/button";
import { Plus } from "lucide-react";

function EventsPageContent() {
  const router = useRouter();
  const {
    user,
    authLoading,
    events,
    venues,
    loading,
    search,
    setSearch,
    statusFilter,
    setStatusFilter,
    tagFilter,
    setTagFilter,
    sortBy,
    setSortBy,
    availableTags,
    filtered,
    onToggleFeatured,
    onSetTopFeatured,
    onDelete,
    getEventStatus,
    getTicketProgress,
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

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex items-center justify-end">
        <Button
          onClick={() => router.push("/events/create")}
          size="lg"
          className="shadow-md"
        >
          <Plus className="mr-2 h-4 w-4" />
          Create Event
        </Button>
      </div>

      <ErrorBoundary fallbackTitle="Search & Stats Error" fallbackMessage="Failed to load search and statistics section.">
        <SearchAndStats
          search={search}
          setSearch={setSearch}
          statusFilter={statusFilter}
          setStatusFilter={setStatusFilter}
          tagFilter={tagFilter}
          setTagFilter={setTagFilter}
          sortBy={sortBy}
          setSortBy={setSortBy}
          availableTags={availableTags}
          events={events}
        />
      </ErrorBoundary>

      {/* Events Grid */}
      <ErrorBoundary fallbackTitle="Events Error" fallbackMessage="Failed to load events. Try refreshing the page.">
        <div className="grid gap-8 md:grid-cols-2 xl:grid-cols-3">
          {loading ? (
            Array.from({length: 6}).map((_, i) => <EventSkeleton key={i} />)
          ) : filtered.length === 0 ? (
            <EmptyEventsState
              search={search}
              onCreateClick={() => router.push("/events/create")}
              userRole={user.role}
            />
          ) : (
            filtered.map((ev, index) => {
              const eventStatus = getEventStatus(ev);
              const ticketProgress = getTicketProgress(ev);

              return (
                <EventCard
                  key={`event-${ev.id}-${index}`}
                  ev={ev}
                  index={index}
                  eventStatus={eventStatus}
                  ticketProgress={ticketProgress}
                  user={user}
                  onToggleFeatured={onToggleFeatured}
                  onSetTopFeatured={onSetTopFeatured}
                  onDelete={onDelete}
                  onEditClick={() => router.push(`/events/${ev.id}/edit`)}
                />
              );
            })
          )}
        </div>
      </ErrorBoundary>
    </div>
  );
}

export default function EventsPage() {
  return (
    <RequireAuth>
      <EventsPageContent />
    </RequireAuth>
  );
}