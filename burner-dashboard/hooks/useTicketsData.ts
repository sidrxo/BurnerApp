import { useEffect, useState } from "react";
import { collectionGroup, getDocs, updateDoc, Timestamp, collection, query, where } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { useAuth } from "@/components/useAuth";
import { toast } from "sonner";

export type Ticket = {
  id: string;
  userID: string;
  userEmail?: string;
  eventName: string;
  eventId?: string;
  venueId?: string;
  ticketNumber?: string;
  totalPrice: number;
  purchaseDate: any;
  status: string;
  isUsed: boolean;
  usedAt?: any;
  docRef?: any;
};

export type EventGroup = {
  eventName: string;
  eventId?: string;
  tickets: Ticket[];
  totalRevenue: number;
  usedCount: number;
  totalCount: number;
};

export type TicketsStats = {
  totalTickets: number;
  usedTickets: number;
  totalRevenue: number;
  activeEvents: number;
};

export function useTicketsData() {
  const { user, loading: authLoading } = useAuth();
  const [tickets, setTickets] = useState<Ticket[]>([]);
  const [eventGroups, setEventGroups] = useState<EventGroup[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [expandedEvents, setExpandedEvents] = useState<Set<string>>(new Set());
  const [viewMode, setViewMode] = useState<'grouped' | 'list'>('grouped');

  useEffect(() => {
    if (!authLoading && user) {
      loadTickets();
    }
  }, [user, authLoading]);

  const loadTickets = async () => {
    if (!user) return;

    setLoading(true);
    try {
      let allTickets: Ticket[] = [];

      const transformTicket = (doc: any) => {
        const data = doc.data();
        const status = (data.status || (data.isUsed ? "used" : "confirmed")) as string;
        const totalPrice = typeof data.totalPrice === "number"
          ? data.totalPrice
          : typeof data.ticketPrice === "number"
            ? data.ticketPrice
            : 0;
        return {
          id: doc.id,
          docRef: doc.ref,
          ...data,
          totalPrice,
          status,
          isUsed: status.toLowerCase() === 'used',
        } as Ticket;
      };

      if (user.role === "siteAdmin") {
        // Site admin sees all tickets
        const snap = await getDocs(collectionGroup(db, "tickets"));
        allTickets = snap.docs.map(transformTicket);
      } else if (user.role === "venueAdmin" || user.role === "subAdmin") {
        if (!user.venueId) {
          toast.error("No venue assigned to your account");
          setLoading(false);
          return;
        }

        // More efficient: Query events for this venue first, then get tickets for those events
        const eventsQuery = query(
          collection(db, "events"),
          where("venueId", "==", user.venueId)
        );
        const eventsSnap = await getDocs(eventsQuery);

        // Fetch tickets for each event in parallel
        const ticketPromises = eventsSnap.docs.map(async (eventDoc) => {
          const ticketsSnap = await getDocs(collection(db, "events", eventDoc.id, "tickets"));
          return ticketsSnap.docs.map(transformTicket);
        });

        const ticketArrays = await Promise.all(ticketPromises);
        allTickets = ticketArrays.flat();
      } else {
        // For scanners or other roles with venue access
        if (user.venueId) {
          const eventsQuery = query(
            collection(db, "events"),
            where("venueId", "==", user.venueId)
          );
          const eventsSnap = await getDocs(eventsQuery);

          const ticketPromises = eventsSnap.docs.map(async (eventDoc) => {
            const ticketsSnap = await getDocs(collection(db, "events", eventDoc.id, "tickets"));
            return ticketsSnap.docs.map(transformTicket);
          });

          const ticketArrays = await Promise.all(ticketPromises);
          allTickets = ticketArrays.flat();
        }
      }

      setTickets(allTickets);
      groupTicketsByEvent(allTickets);
    } catch (e: any) {
      toast.error("Failed to load tickets: " + e.message);
    } finally {
      setLoading(false);
    }
  };

  const groupTicketsByEvent = (ticketList: Ticket[]) => {
    const groups: Record<string, EventGroup> = {};
    
    ticketList.forEach(ticket => {
      const eventKey = ticket.eventName || 'Unknown Event';
      
      if (!groups[eventKey]) {
        groups[eventKey] = {
          eventName: eventKey,
          eventId: ticket.eventId,
          tickets: [],
          totalRevenue: 0,
          usedCount: 0,
          totalCount: 0,
        };
      }
      
      const group = groups[eventKey];
      group.tickets.push(ticket);
      // Safely add ticketPrice with fallback to 0
      const price = typeof ticket.totalPrice === 'number' && !isNaN(ticket.totalPrice) ? ticket.totalPrice : 0;
      group.totalRevenue += price;
      group.totalCount++;
      if (ticket.isUsed) {
        group.usedCount++;
      }
    });

    // Sort groups by total revenue (highest first)
    const sortedGroups = Object.values(groups).sort((a, b) => b.totalRevenue - a.totalRevenue);
    setEventGroups(sortedGroups);
  };

  const filteredEventGroups = eventGroups.filter(group => {
    if (!search) return true;
    const searchLower = search.toLowerCase();
    return (
      group.eventName.toLowerCase().includes(searchLower) ||
      group.tickets.some(ticket => 
        ticket.userEmail?.toLowerCase().includes(searchLower) ||
        ticket.userID?.toLowerCase().includes(searchLower)
      )
    );
  });

  const filteredTickets = tickets.filter(t => {
    if (!search) return true;
    const searchLower = search.toLowerCase();
    return (
      t.userEmail?.toLowerCase().includes(searchLower) ||
      t.eventName?.toLowerCase().includes(searchLower) ||
      t.userID?.toLowerCase().includes(searchLower)
    );
  });

  const markUsed = async (ticket: Ticket) => {
    if (ticket.isUsed) return;
    try {
      if (ticket.docRef) {
        await updateDoc(ticket.docRef, { status: 'used', usedAt: Timestamp.now() });
      }
      toast.success("Ticket marked as used!");
      loadTickets();
    } catch (e: any) {
      toast.error("Error updating ticket: " + e.message);
    }
  };

  const toggleEventExpansion = (eventName: string) => {
    const newExpanded = new Set(expandedEvents);
    if (newExpanded.has(eventName)) {
      newExpanded.delete(eventName);
    } else {
      newExpanded.add(eventName);
    }
    setExpandedEvents(newExpanded);
  };

  const stats: TicketsStats = {
    totalTickets: tickets.length,
    usedTickets: tickets.filter(t => t.isUsed).length,
    totalRevenue: tickets.reduce((sum, t) => {
      const price = typeof t.totalPrice === 'number' && !isNaN(t.totalPrice) ? t.totalPrice : 0;
      return sum + price;
    }, 0),
    activeEvents: eventGroups.length
  };

  return {
    user,
    authLoading,
    tickets,
    eventGroups,
    loading,
    search,
    setSearch,
    expandedEvents,
    viewMode,
    setViewMode,
    filteredEventGroups,
    filteredTickets,
    markUsed,
    toggleEventExpansion,
    loadTickets,
    stats
  };
}