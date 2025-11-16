"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { doc, getDoc } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { Event } from "@/hooks/usePublicEvents";
import Image from "next/image";
import { useAuth } from "@/components/useAuth";

export default function EventDetailPage() {
  const params = useParams();
  const router = useRouter();
  const { user } = useAuth();
  const [event, setEvent] = useState<Event | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchEvent = async () => {
      try {
        setLoading(true);
        const eventDoc = await getDoc(doc(db, "events", params.eventId as string));

        if (!eventDoc.exists()) {
          setError("Event not found");
          return;
        }

        setEvent({ id: eventDoc.id, ...eventDoc.data() } as Event);
      } catch (err) {
        console.error("Error fetching event:", err);
        setError("Failed to load event");
      } finally {
        setLoading(false);
      }
    };

    if (params.eventId) {
      fetchEvent();
    }
  }, [params.eventId]);

  const formatDate = (timestamp: any) => {
    if (!timestamp) return "";
    try {
      const date = timestamp.toDate();
      return new Intl.DateTimeFormat("en-GB", {
        weekday: "long",
        day: "numeric",
        month: "long",
        year: "numeric",
        hour: "2-digit",
        minute: "2-digit",
      }).format(date);
    } catch {
      return "";
    }
  };

  const formatPrice = (price: number) => {
    return new Intl.NumberFormat("en-GB", {
      style: "currency",
      currency: "GBP",
    }).format(price / 100);
  };

  const handlePurchase = () => {
    if (!user) {
      // Redirect to sign in with return URL
      router.push(`/signin?return=/events/${params.eventId}/purchase`);
      return;
    }
    router.push(`/events/${params.eventId}/purchase`);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center space-y-4">
          <div className="w-8 h-8 border-2 border-white/20 border-t-white rounded-full animate-spin mx-auto" />
          <p className="text-white/50">Loading event...</p>
        </div>
      </div>
    );
  }

  if (error || !event) {
    return (
      <div className="flex items-center justify-center min-h-screen px-4">
        <div className="text-center space-y-4">
          <p className="text-white/70">{error || "Event not found"}</p>
          <button
            onClick={() => router.push("/")}
            className="px-6 py-2 bg-white text-black rounded-lg font-medium hover:bg-white/90 transition-colors"
          >
            Back to Events
          </button>
        </div>
      </div>
    );
  }

  const remainingTickets = event.maxTickets - event.ticketsSold;
  const soldOut = remainingTickets <= 0;

  return (
    <div className="min-h-screen pb-12">
      {/* Back Button */}
      <div className="px-4 py-4 max-w-4xl mx-auto">
        <button
          onClick={() => router.back()}
          className="flex items-center gap-2 text-white/70 hover:text-white transition-colors"
        >
          <svg
            className="w-5 h-5"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M15 19l-7-7 7-7"
            />
          </svg>
          Back
        </button>
      </div>

      {/* Event Hero Image */}
      {event.imageUrl && (
        <div className="relative w-full h-64 md:h-96 mb-8">
          <Image
            src={event.imageUrl}
            alt={event.name}
            fill
            className="object-cover"
            priority
          />
          {soldOut && (
            <div className="absolute inset-0 bg-black/60 flex items-center justify-center">
              <span className="text-white text-3xl font-bold">SOLD OUT</span>
            </div>
          )}
        </div>
      )}

      {/* Event Details */}
      <div className="px-4 max-w-4xl mx-auto space-y-8">
        {/* Title and Venue */}
        <div className="space-y-4">
          <h1 className="text-4xl md:text-5xl font-bold">{event.name}</h1>
          {event.venue && (
            <div className="flex items-center gap-2 text-white/70">
              <svg
                className="w-5 h-5"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"
                />
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"
                />
              </svg>
              <span className="text-lg">{event.venue}</span>
            </div>
          )}
        </div>

        {/* Date & Time */}
        {event.startTime && (
          <div className="flex items-start gap-2 text-white/70">
            <svg
              className="w-5 h-5 mt-1"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
              />
            </svg>
            <span className="text-lg">{formatDate(event.startTime)}</span>
          </div>
        )}

        {/* Description */}
        {event.description && (
          <div className="space-y-3">
            <h2 className="text-2xl font-bold">About</h2>
            <p className="text-white/70 text-lg whitespace-pre-wrap leading-relaxed">
              {event.description}
            </p>
          </div>
        )}

        {/* Price and Availability */}
        <div className="bg-white/5 border border-white/10 rounded-xl p-6 space-y-4">
          <div className="flex items-center justify-between">
            <span className="text-white/70">Price</span>
            <span className="text-3xl font-bold">{formatPrice(event.price)}</span>
          </div>
          {!soldOut && (
            <div className="flex items-center justify-between">
              <span className="text-white/70">Tickets Available</span>
              <span className="text-xl font-medium">{remainingTickets}</span>
            </div>
          )}
        </div>

        {/* Purchase Button */}
        <button
          onClick={handlePurchase}
          disabled={soldOut}
          className={`
            w-full py-4 rounded-xl font-bold text-lg transition-all duration-300
            ${
              soldOut
                ? "bg-white/10 text-white/30 cursor-not-allowed"
                : "bg-white text-black hover:bg-white/90"
            }
          `}
        >
          {soldOut ? "Sold Out" : "Buy Ticket"}
        </button>

        {/* Terms */}
        <p className="text-white/30 text-sm text-center">
          By purchasing a ticket, you agree to our{" "}
          <a href="/terms" className="underline hover:text-white/50">
            Terms of Service
          </a>{" "}
          and{" "}
          <a href="/privacy" className="underline hover:text-white/50">
            Privacy Policy
          </a>
        </p>
      </div>
    </div>
  );
}
