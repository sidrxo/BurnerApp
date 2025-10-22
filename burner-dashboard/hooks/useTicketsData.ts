import { useEffect, useState, useCallback } from "react";
import {
  collectionGroup,
  getDocs,
  updateDoc,
  Timestamp,
  collection,
  query,
  where,
  orderBy,
  limit,
  startAfter,
  QueryDocumentSnapshot,
  onSnapshot,
  doc,
  getDoc
} from "firebase/firestore";
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

const PAGE_SIZE = 50; // Load 50 tickets at a time
const DEFAULT_DATE_RANGE_DAYS = 90; // Default to last 90 days

export function useTicketsData() {
  const { user, loading: authLoading } = useAuth();
  const [tickets, setTickets] = useState<Ticket[]>([]);
  const [eventGroups, setEventGroups] = useState<EventGroup[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [search, setSearch] = useState("");
  const [expandedEvents, setExpandedEvents] = useState<Set<string>>(new Set());
  const [viewMode, setViewMode] = useState<'grouped' | 'list'>('grouped');
  const [lastVisible, setLastVisible] = useState<QueryDocumentSnapshot | null>(null);
  const [hasMore, setHasMore] = useState(true);
  const [dateFilter, setDateFilter] = useState<number>(DEFAULT_DATE_RANGE_DAYS); // days to look back
  const [stats, setStats] = useState<TicketsStats>({
    totalTickets: 0,
    usedTickets: 0,
    totalRevenue: 0,
    activeEvents: 0
  });

  useEffect(() => {
    if (!authLoading && user) {
      loadTickets(true);
      loadStats();
    }
  }, [user, authLoading, dateFilter]);

  const transformTicket = useCallback((doc: any) => {
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
  }, []);

  // Load aggregated stats from eventStats collection instead of counting all tickets
  const loadStats = async () => {
    if (!user) return;

    try {
      let totalTickets = 0;
      let usedTickets = 0;
      let totalRevenue = 0;
      let activeEvents = 0;

      if (user.role === "siteAdmin") {
        // Load all eventStats
        const eventStatsSnap = await getDocs(collection(db, "eventStats"));
        eventStatsSnap.forEach(doc => {
          const data = doc.data();
          totalTickets += data.ticketsSold || 0;
          usedTickets += data.ticketsUsed || 0;
          totalRevenue += data.totalRevenue || 0;
          activeEvents++;
        });
      } else if (user.role === "venueAdmin" || user.role === "subAdmin") {
        if (!user.venueId) return;

        // Load eventStats for this venue
        const eventStatsQuery = query(
          collection(db, "eventStats"),
          where("venueId", "==", user.venueId)
        );
        const eventStatsSnap = await getDocs(eventStatsQuery);
        eventStatsSnap.forEach(doc => {
          const data = doc.data();
          totalTickets += data.ticketsSold || 0;
          usedTickets += data.ticketsUsed || 0;
          totalRevenue += data.totalRevenue || 0;
          activeEvents++;
        });
      }

      setStats({
        totalTickets,
        usedTickets,
        totalRevenue,
        activeEvents
      });
    } catch (e: any) {
      console.error("Failed to load stats:", e);
    }
  };

  const loadTickets = async (reset: boolean = false) => {
    if (!user) return;

    if (reset) {
      setLoading(true);
      setLastVisible(null);
      setHasMore(true);
      setTickets([]);
    } else {
      setLoadingMore(true);
    }

    try {
      let allTickets: Ticket[] = reset ? [] : [...tickets];

      // Calculate date cutoff for filtering
      const dateCutoff = Timestamp.fromDate(
        new Date(Date.now() - dateFilter * 24 * 60 * 60 * 1000)
      );

      if (user.role === "siteAdmin") {
        // Site admin: Use collection group query with date filter and pagination
        const ticketsQuery = lastVisible && !reset
          ? query(
              collectionGroup(db, "tickets"),
              where("purchaseDate", ">=", dateCutoff),
              orderBy("purchaseDate", "desc"),
              startAfter(lastVisible),
              limit(PAGE_SIZE)
            )
          : query(
              collectionGroup(db, "tickets"),
              where("purchaseDate", ">=", dateCutoff),
              orderBy("purchaseDate", "desc"),
              limit(PAGE_SIZE)
            );

        const snap = await getDocs(ticketsQuery);
        const newTickets = snap.docs.map(transformTicket);
        allTickets = [...allTickets, ...newTickets];

        // Update pagination state
        if (snap.docs.length > 0) {
          setLastVisible(snap.docs[snap.docs.length - 1]);
        }
        setHasMore(snap.docs.length === PAGE_SIZE);

      } else if (user.role === "venueAdmin" || user.role === "subAdmin") {
        if (!user.venueId) {
          toast.error("No venue assigned to your account");
          setLoading(false);
          setLoadingMore(false);
          return;
        }

        // Load events for this venue with date filter
        const eventsQuery = query(
          collection(db, "events"),
          where("venueId", "==", user.venueId),
          where("startTime", ">=", dateCutoff)
        );
        const eventsSnap = await getDocs(eventsQuery);

        // Fetch tickets for each event in parallel (limited to PAGE_SIZE total)
        let loadedCount = 0;
        const ticketPromises = eventsSnap.docs.map(async (eventDoc) => {
          if (loadedCount >= PAGE_SIZE) return [];

          const ticketsQuery = query(
            collection(db, "events", eventDoc.id, "tickets"),
            orderBy("purchaseDate", "desc"),
            limit(Math.min(PAGE_SIZE - loadedCount, 20)) // Limit per event
          );
          const ticketsSnap = await getDocs(ticketsQuery);
          loadedCount += ticketsSnap.docs.length;
          return ticketsSnap.docs.map(transformTicket);
        });

        const ticketArrays = await Promise.all(ticketPromises);
        const newTickets = ticketArrays.flat();
        allTickets = [...allTickets, ...newTickets];

        // For venue admins, we don't have perfect pagination across events
        // So we just disable "load more" after first load
        setHasMore(false);

      } else {
        // For scanners or other roles with venue access
        if (user.venueId) {
          const eventsQuery = query(
            collection(db, "events"),
            where("venueId", "==", user.venueId),
            where("startTime", ">=", dateCutoff)
          );
          const eventsSnap = await getDocs(eventsQuery);

          const ticketPromises = eventsSnap.docs.map(async (eventDoc) => {
            const ticketsQuery = query(
              collection(db, "events", eventDoc.id, "tickets"),
              orderBy("purchaseDate", "desc"),
              limit(PAGE_SIZE)
            );
            const ticketsSnap = await getDocs(ticketsQuery);
            return ticketsSnap.docs.map(transformTicket);
          });

          const ticketArrays = await Promise.all(ticketPromises);
          allTickets = ticketArrays.flat();
          setHasMore(false);
        }
      }

      setTickets(allTickets);
      groupTicketsByEvent(allTickets);
    } catch (e: any) {
      toast.error("Failed to load tickets: " + e.message);
    } finally {
      setLoading(false);
      setLoadingMore(false);
    }
  };

  const loadMore = useCallback(() => {
    if (!loadingMore && hasMore) {
      loadTickets(false);
    }
  }, [loadingMore, hasMore, lastVisible, tickets]);

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
      loadTickets(true); // Reload to refresh data
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

  const refreshData = () => {
    loadTickets(true);
    loadStats();
  };

  const changeDateFilter = (days: number) => {
    setDateFilter(days);
    // This will trigger useEffect to reload tickets
  };

  return {
    user,
    authLoading,
    tickets,
    eventGroups,
    loading,
    loadingMore,
    hasMore,
    search,
    setSearch,
    expandedEvents,
    viewMode,
    setViewMode,
    filteredEventGroups,
    filteredTickets,
    markUsed,
    toggleEventExpansion,
    loadTickets: refreshData,
    loadMore,
    stats,
    dateFilter,
    changeDateFilter
  };
}
