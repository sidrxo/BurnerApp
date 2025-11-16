"use client";

import Link from "next/link";
import Image from "next/image";
import { Event } from "@/hooks/usePublicEvents";

interface EventCardProps {
  event: Event;
  featured?: boolean;
}

export function EventCard({ event, featured = false }: EventCardProps) {
  const formatDate = (timestamp: any) => {
    if (!timestamp) return "";
    try {
      const date = timestamp.toDate();
      return new Intl.DateTimeFormat("en-GB", {
        weekday: "short",
        day: "numeric",
        month: "short",
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

  return (
    <Link href={`/events/${event.id}`}>
      <div
        className={`
          bg-white/5 border border-white/10 rounded-xl overflow-hidden
          hover:bg-white/10 hover:border-white/20 transition-all duration-300
          ${featured ? "md:col-span-2 md:row-span-2" : ""}
        `}
      >
        {/* Event Image */}
        {event.imageUrl && (
          <div className={`relative w-full ${featured ? "h-64 md:h-96" : "h-48"} bg-white/5`}>
            <Image
              src={event.imageUrl}
              alt={event.name}
              fill
              className="object-cover"
              sizes={featured ? "(max-width: 768px) 100vw, 50vw" : "(max-width: 768px) 100vw, 33vw"}
            />
          </div>
        )}

        {/* Event Details */}
        <div className={`p-4 ${featured ? "md:p-6" : ""}`}>
          <div className="space-y-2">
            {/* Event Name */}
            <h3 className={`font-bold ${featured ? "text-2xl md:text-3xl" : "text-lg"} line-clamp-2`}>
              {event.name}
            </h3>

            {/* Venue */}
            {event.venue && (
              <p className="text-white/70 text-sm">{event.venue}</p>
            )}

            {/* Date & Time */}
            {event.startTime && (
              <p className="text-white/50 text-sm">{formatDate(event.startTime)}</p>
            )}

            {/* Description (featured only) */}
            {featured && event.description && (
              <p className="text-white/70 text-sm line-clamp-3 mt-3">
                {event.description}
              </p>
            )}

            {/* Tags */}
            {event.tags && event.tags.length > 0 && (
              <div className="flex flex-wrap gap-1.5 mt-2">
                {event.tags.slice(0, 3).map((tag, idx) => (
                  <span
                    key={idx}
                    className="px-2 py-0.5 bg-white/10 rounded-full text-xs text-white/70"
                  >
                    {tag}
                  </span>
                ))}
              </div>
            )}

            {/* Bottom row: Price & Category */}
            <div className="flex items-center justify-between pt-2">
              <span className={`font-bold ${featured ? "text-xl" : "text-lg"}`}>
                {formatPrice(event.price)}
              </span>
              {event.category && (
                <span className="text-white/50 text-sm capitalize">
                  {event.category}
                </span>
              )}
            </div>
          </div>
        </div>
      </div>
    </Link>
  );
}
