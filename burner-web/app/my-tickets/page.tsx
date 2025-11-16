"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { collection, query, where, getDocs, Timestamp } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { useAuth } from "@/components/useAuth";
import Image from "next/image";
import QRCode from "qrcode";

interface Ticket {
  id: string;
  eventId: string;
  eventName: string;
  eventImage?: string;
  venue?: string;
  startTime?: Timestamp;
  price: number;
  status: string;
  qrCode?: string;
}

export default function MyTicketsPage() {
  const router = useRouter();
  const { user, loading: authLoading } = useAuth();
  const [tickets, setTickets] = useState<Ticket[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedTicket, setSelectedTicket] = useState<Ticket | null>(null);
  const [qrDataUrl, setQrDataUrl] = useState<string>("");

  useEffect(() => {
    if (authLoading) return;

    if (!user) {
      router.push("/signin?return=/my-tickets");
      return;
    }

    const fetchTickets = async () => {
      try {
        setLoading(true);
        const ticketsRef = collection(db, "tickets");
        const q = query(ticketsRef, where("userId", "==", user.uid));
        const snapshot = await getDocs(q);

        const ticketsData = await Promise.all(
          snapshot.docs.map(async (ticketDoc) => {
            const ticket = ticketDoc.data();

            // Fetch event details
            const eventDoc = await getDocs(
              query(collection(db, "events"), where("__name__", "==", ticket.eventId))
            );

            let eventData: any = {};
            if (!eventDoc.empty) {
              eventData = eventDoc.docs[0].data();
            }

            return {
              id: ticketDoc.id,
              eventId: ticket.eventId,
              eventName: eventData.name || ticket.eventName || "Unknown Event",
              eventImage: eventData.imageUrl,
              venue: eventData.venue,
              startTime: eventData.startTime,
              price: ticket.price || eventData.price || 0,
              status: ticket.status || "confirmed",
            } as Ticket;
          })
        );

        setTickets(ticketsData);
      } catch (err) {
        console.error("Error fetching tickets:", err);
        setError("Failed to load tickets");
      } finally {
        setLoading(false);
      }
    };

    fetchTickets();
  }, [user, authLoading, router]);

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

  const showQRCode = async (ticket: Ticket) => {
    try {
      const qrData = await QRCode.toDataURL(ticket.id, {
        width: 300,
        margin: 2,
        color: {
          dark: "#000000",
          light: "#ffffff",
        },
      });
      setQrDataUrl(qrData);
      setSelectedTicket(ticket);
    } catch (err) {
      console.error("Error generating QR code:", err);
    }
  };

  if (authLoading || loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center space-y-4">
          <div className="w-8 h-8 border-2 border-white/20 border-t-white rounded-full animate-spin mx-auto" />
          <p className="text-white/50">Loading tickets...</p>
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
    <div className="min-h-screen pb-12">
      {/* Header */}
      <div className="px-4 py-8 max-w-4xl mx-auto">
        <div className="flex items-center justify-between mb-8">
          <h1 className="text-4xl font-bold">My Tickets</h1>
          <button
            onClick={() => router.push("/")}
            className="text-white/70 hover:text-white transition-colors"
          >
            Browse Events
          </button>
        </div>

        {/* Tickets List */}
        {tickets.length === 0 ? (
          <div className="text-center py-12 space-y-4">
            <p className="text-white/50 text-lg">No tickets yet</p>
            <button
              onClick={() => router.push("/")}
              className="px-6 py-3 bg-white text-black rounded-xl font-medium hover:bg-white/90 transition-colors"
            >
              Browse Events
            </button>
          </div>
        ) : (
          <div className="space-y-4">
            {tickets.map((ticket) => (
              <div
                key={ticket.id}
                className="bg-white/5 border border-white/10 rounded-xl overflow-hidden hover:bg-white/10 transition-all"
              >
                <div className="flex gap-4 p-4">
                  {/* Event Image */}
                  {ticket.eventImage && (
                    <div className="relative w-24 h-24 rounded-lg overflow-hidden flex-shrink-0">
                      <Image
                        src={ticket.eventImage}
                        alt={ticket.eventName}
                        fill
                        className="object-cover"
                      />
                    </div>
                  )}

                  {/* Ticket Details */}
                  <div className="flex-1 min-w-0">
                    <h3 className="text-xl font-bold mb-1 truncate">
                      {ticket.eventName}
                    </h3>
                    {ticket.venue && (
                      <p className="text-white/70 text-sm mb-1">{ticket.venue}</p>
                    )}
                    {ticket.startTime && (
                      <p className="text-white/50 text-sm mb-2">
                        {formatDate(ticket.startTime)}
                      </p>
                    )}
                    <div className="flex items-center gap-3">
                      <span className="text-white/70">{formatPrice(ticket.price)}</span>
                      <span
                        className={`px-2 py-1 rounded text-xs ${
                          ticket.status === "used"
                            ? "bg-white/10 text-white/50"
                            : "bg-green-500/20 text-green-400"
                        }`}
                      >
                        {ticket.status === "used" ? "Used" : "Valid"}
                      </span>
                    </div>
                  </div>

                  {/* Show QR Button */}
                  <button
                    onClick={() => showQRCode(ticket)}
                    className="px-4 py-2 bg-white text-black rounded-lg font-medium hover:bg-white/90 transition-colors self-center"
                  >
                    Show QR
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* QR Code Modal */}
      {selectedTicket && (
        <div
          className="fixed inset-0 bg-black/80 flex items-center justify-center p-4 z-50"
          onClick={() => {
            setSelectedTicket(null);
            setQrDataUrl("");
          }}
        >
          <div
            className="bg-white rounded-xl p-8 max-w-md w-full"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="text-center space-y-4">
              <h2 className="text-2xl font-bold text-black">
                {selectedTicket.eventName}
              </h2>
              {qrDataUrl && (
                <img
                  src={qrDataUrl}
                  alt="Ticket QR Code"
                  className="mx-auto"
                />
              )}
              <p className="text-black/70 text-sm">
                Show this QR code at the venue entrance
              </p>
              <button
                onClick={() => {
                  setSelectedTicket(null);
                  setQrDataUrl("");
                }}
                className="w-full py-3 bg-black text-white rounded-lg font-medium hover:bg-black/90 transition-colors"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
