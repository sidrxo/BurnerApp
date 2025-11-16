"use client";

import { usePublicEvents } from "@/hooks/usePublicEvents";
import { EventCard } from "@/components/public/event-card";

export default function ExplorePage() {
  const { events, featuredEvents, loading, error } = usePublicEvents();

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center space-y-4">
          <div className="w-8 h-8 border-2 border-white/20 border-t-white rounded-full animate-spin mx-auto" />
          <p className="text-white/50">Loading events...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex items-center justify-center min-h-screen px-4">
        <div className="text-center space-y-4">
          <p className="text-white/70">{error}</p>
          <button
            onClick={() => window.location.reload()}
            className="px-6 py-2 bg-white text-black rounded-lg font-medium hover:bg-white/90 transition-colors"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen">
      {/* Hero Section */}
      <section className="px-4 py-8 md:py-12 max-w-7xl mx-auto">
        <div className="space-y-4 mb-8">
          <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold tracking-tight">
            Discover Events
          </h1>
          <p className="text-white/70 text-lg md:text-xl max-w-2xl">
            Find and book tickets to the hottest events happening near you.
          </p>
        </div>
      </section>

      {/* Featured Events */}
      {featuredEvents.length > 0 && (
        <section className="px-4 pb-12 max-w-7xl mx-auto">
          <h2 className="text-2xl md:text-3xl font-bold mb-6">Featured Events</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 md:gap-6">
            {featuredEvents.map((event) => (
              <EventCard key={event.id} event={event} featured />
            ))}
          </div>
        </section>
      )}

      {/* All Events */}
      <section className="px-4 pb-12 max-w-7xl mx-auto">
        <h2 className="text-2xl md:text-3xl font-bold mb-6">
          {featuredEvents.length > 0 ? "All Events" : "Events"}
        </h2>

        {events.length === 0 ? (
          <div className="text-center py-12">
            <p className="text-white/50 text-lg">No events available at the moment.</p>
            <p className="text-white/30 text-sm mt-2">Check back soon for upcoming events!</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 md:gap-6">
            {events.map((event) => (
              <EventCard key={event.id} event={event} />
            ))}
          </div>
        )}
      </section>
    </div>
  );
}
