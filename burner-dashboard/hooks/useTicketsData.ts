import { useEffect, useState, useCallback } from "react";
import { supabase } from "@/lib/supabase";
import { useAuth } from "@/components/useAuth";
import { toast } from "sonner";

export type Ticket = {
  id: string;
  user_id: string;
  user_email?: string;
  event_name: string;
  event_id?: string;
  venue_id?: string;
  ticket_number?: string;
  total_price: number;
  purchase_date: string;
  status: string;
  is_used: boolean;
  used_at?: string;
  // Legacy camelCase for backward compatibility
  userID?: string;
  userEmail?: string;
  eventName?: string;
  eventId?: string;
  venueId?: string;
  ticketNumber?: string;
  totalPrice?: number;
  purchaseDate?: string;
  isUsed?: boolean;
  usedAt?: string;
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
const CACHE_TTL = 5 * 60 * 1000; // 5 minutes cache

// Simple in-memory cache
const cache = new Map<string, { data: any; timestamp: number }>();

function getCacheKey(userId: string, role: string, venueId?: string | null): string  {
  return `tickets_${userId}_${role}_${venueId || 'all'}`;
}

function getFromCache<T>(key: string): T | null {
  const cached = cache.get(key);
  if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
    return cached.data as T;
  }
  cache.delete(key);
  return null;
}

function setCache(key: string, data: any): void {
  cache.set(key, { data, timestamp: Date.now() });
}

export function useTicketsData() {
  const { user, loading: authLoading } = useAuth();
  const [tickets, setTickets] = useState<Ticket[]>([]);
  const [eventGroups, setEventGroups] = useState<EventGroup[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [search, setSearch] = useState("");
  const [expandedEvents, setExpandedEvents] = useState<Set<string>>(new Set());
  const [viewMode, setViewMode] = useState<'grouped' | 'list'>('grouped');
  const [currentOffset, setCurrentOffset] = useState<number>(0);
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

  const transformTicket = useCallback((data: any) => {
    const status = (data.status || (data.is_used ? "used" : "confirmed")) as string;
    const totalPrice = typeof data.total_price === "number"
      ? data.total_price
      : typeof data.ticket_price === "number"
        ? data.ticket_price
        : 0;

    // Extract email from joined users table or fallback to user_email field
    const userEmail = data.users?.email || data.user_email || '';

    // Return both snake_case (primary) and camelCase (compatibility)
    return {
      id: data.id,
      user_id: data.user_id,
      user_email: userEmail,
      event_name: data.event_name,
      event_id: data.event_id,
      venue_id: data.venue_id,
      ticket_number: data.ticket_number,
      total_price: totalPrice,
      purchase_date: data.purchase_date,
      status,
      is_used: status.toLowerCase() === 'used',
      used_at: data.used_at,
      // Legacy camelCase for backward compatibility
      userID: data.user_id,
      userEmail: userEmail,
      eventName: data.event_name,
      eventId: data.event_id,
      venueId: data.venue_id,
      ticketNumber: data.ticket_number,
      totalPrice: totalPrice,
      purchaseDate: data.purchase_date,
      isUsed: status.toLowerCase() === 'used',
      usedAt: data.used_at,
    } as Ticket;
  }, []);

  // Load aggregated stats with caching
  const loadStats = async () => {
    if (!user) return;

    const statsCacheKey = `stats_${user.uid}_${user.role}_${user.venueId || 'all'}`;
    const cachedStats = getFromCache<TicketsStats>(statsCacheKey);
    if (cachedStats) {
      setStats(cachedStats);
      return;
    }

    try {
      let totalTickets = 0;
      let usedTickets = 0;
      let totalRevenue = 0;
      let activeEvents = 0;

      // Calculate date cutoff for filtering
      const dateCutoff = new Date(Date.now() - dateFilter * 24 * 60 * 60 * 1000).toISOString();

      if (user.role === "siteAdmin") {
        // Aggregate all tickets across all events
        const { data: ticketsData, error } = await supabase
          .from('tickets')
          .select('total_price, status, event_id')
          .gte('purchase_date', dateCutoff);

        if (error) throw error;

        const eventIds = new Set<string>();
        ticketsData?.forEach((ticket: any) => {
          totalTickets++;
          totalRevenue += ticket.total_price || 0;
          if (ticket.status === 'used') usedTickets++;
          if (ticket.event_id) eventIds.add(ticket.event_id);
        });
        activeEvents = eventIds.size;

      } else if (user.role === "organiser") {
        // Organisers: Get stats from their assigned venues
        const { data: organiserVenuesData, error: organiserVenuesError } = await supabase
          .from('organizer_venues')
          .select('venue_id')
          .eq('organizer_id', user.uid);

        if (organiserVenuesError) throw organiserVenuesError;

        const venueIds = organiserVenuesData?.map((ov: any) => ov.venue_id) || [];

        if (venueIds.length > 0) {
          // Get events for these venues
          const { data: eventsData, error: eventsError } = await supabase
            .from('events')
            .select('id')
            .in('venue_id', venueIds);

          if (eventsError) throw eventsError;

          const eventIds = eventsData?.map((e: any) => e.id) || [];
          activeEvents = eventIds.length;

          if (eventIds.length > 0) {
            // Aggregate tickets for these events
            const { data: ticketsData, error } = await supabase
              .from('tickets')
              .select('total_price, status')
              .in('event_id', eventIds)
              .gte('purchase_date', dateCutoff);

            if (error) throw error;

            ticketsData?.forEach((ticket: any) => {
              totalTickets++;
              totalRevenue += ticket.total_price || 0;
              if (ticket.status === 'used') usedTickets++;
            });
          }
        }

      } else if (user.role === "venueAdmin" || user.role === "subAdmin") {
        if (!user.venueId) return;

        // Get events for this venue first
        const { data: eventsData, error: eventsError } = await supabase
          .from('events')
          .select('id')
          .eq('venue_id', user.venueId);

        if (eventsError) throw eventsError;

        const eventIds = eventsData?.map((e: any) => e.id) || [];
        activeEvents = eventIds.length;

        if (eventIds.length > 0) {
          // Aggregate tickets for this venue's events
          const { data: ticketsData, error } = await supabase
            .from('tickets')
            .select('total_price, status')
            .in('event_id', eventIds)
            .gte('purchase_date', dateCutoff);

          if (error) throw error;

          ticketsData?.forEach((ticket: any) => {
            totalTickets++;
            totalRevenue += ticket.total_price || 0;
            if (ticket.status === 'used') usedTickets++;
          });
        }
      }

      const statsData = {
        totalTickets,
        usedTickets,
        totalRevenue,
        activeEvents
      };

      setStats(statsData);
      setCache(statsCacheKey, statsData);
    } catch (e: any) {
      console.error("Failed to load stats:", e);
    }
  };

  const loadTickets = async (reset: boolean = false, skipCache: boolean = false) => {
    if (!user) return;

    // Check cache first on initial load
    if (reset && !skipCache) {
      const cacheKey = getCacheKey(user.uid, user.role, user.venueId);
      const cachedTickets = getFromCache<Ticket[]>(cacheKey);
      if (cachedTickets && cachedTickets.length > 0) {
        setTickets(cachedTickets);
        groupTicketsByEvent(cachedTickets);
        setLoading(false);
        return;
      }
    }

    if (reset) {
      setLoading(true);
      setCurrentOffset(0);
      setHasMore(true);
      setTickets([]);
    } else {
      setLoadingMore(true);
    }

    try {
      let allTickets: Ticket[] = reset ? [] : [...tickets];

      // Calculate date cutoff for filtering
      const dateCutoff = new Date(Date.now() - dateFilter * 24 * 60 * 60 * 1000).toISOString();

      const offset = reset ? 0 : currentOffset;

      if (user.role === "siteAdmin") {
        // Site admin: Query all tickets with date filter and pagination, joining with users to get email
        const { data, error } = await supabase
          .from('tickets')
          .select('*, users!tickets_user_id_fkey(email)')
          .gte('purchase_date', dateCutoff)
          .order('purchase_date', { ascending: false })
          .range(offset, offset + PAGE_SIZE - 1);

        if (error) throw error;

        const newTickets = (data || []).map(transformTicket);
        allTickets = [...allTickets, ...newTickets];

        // Update pagination state
        setCurrentOffset(offset + newTickets.length);
        setHasMore(newTickets.length === PAGE_SIZE);

      } else if (user.role === "organiser") {
        // Organisers: Get their assigned venues from organizer_venues junction table
        const { data: organiserVenuesData, error: organiserVenuesError } = await supabase
          .from('organizer_venues')
          .select('venue_id')
          .eq('organizer_id', user.uid);

        if (organiserVenuesError) throw organiserVenuesError;

        const venueIds = organiserVenuesData?.map((ov: any) => ov.venue_id) || [];

        if (venueIds.length > 0) {
          // Get events for these venues
          const { data: eventsData, error: eventsError } = await supabase
            .from('events')
            .select('id')
            .in('venue_id', venueIds)
            .gte('start_time', dateCutoff);

          if (eventsError) throw eventsError;

          const eventIds = eventsData?.map((e: any) => e.id) || [];

          if (eventIds.length > 0) {
            // Query tickets for these events with pagination, joining with users to get email
            const { data, error } = await supabase
              .from('tickets')
              .select('*, users!tickets_user_id_fkey(email)')
              .in('event_id', eventIds)
              .order('purchase_date', { ascending: false })
              .range(offset, offset + PAGE_SIZE - 1);

            if (error) throw error;

            const newTickets = (data || []).map(transformTicket);
            allTickets = [...allTickets, ...newTickets];

            // Update pagination state
            setCurrentOffset(offset + newTickets.length);
            setHasMore(newTickets.length === PAGE_SIZE);
          } else {
            setHasMore(false);
          }
        } else {
          setHasMore(false);
        }

      } else if (user.role === "venueAdmin" || user.role === "subAdmin") {
        if (!user.venueId) {
          toast.error("No venue assigned to your account");
          setLoading(false);
          setLoadingMore(false);
          return;
        }

        // Get events for this venue
        const { data: eventsData, error: eventsError } = await supabase
          .from('events')
          .select('id')
          .eq('venue_id', user.venueId)
          .gte('start_time', dateCutoff);

        if (eventsError) throw eventsError;

        const eventIds = eventsData?.map((e: any) => e.id) || [];

        if (eventIds.length > 0) {
          // Query tickets for this venue's events with pagination, joining with users to get email
          const { data, error } = await supabase
            .from('tickets')
            .select('*, users!tickets_user_id_fkey(email)')
            .in('event_id', eventIds)
            .order('purchase_date', { ascending: false })
            .range(offset, offset + PAGE_SIZE - 1);

          if (error) throw error;

          const newTickets = (data || []).map(transformTicket);
          allTickets = [...allTickets, ...newTickets];

          // Update pagination state
          setCurrentOffset(offset + newTickets.length);
          setHasMore(newTickets.length === PAGE_SIZE);
        } else {
          setHasMore(false);
        }

      } else {
        // For scanners or other roles with venue access
        if (user.venueId) {
          // Get events for this venue
          const { data: eventsData, error: eventsError } = await supabase
            .from('events')
            .select('id')
            .eq('venue_id', user.venueId)
            .gte('start_time', dateCutoff);

          if (eventsError) throw eventsError;

          const eventIds = eventsData?.map((e: any) => e.id) || [];

          if (eventIds.length > 0) {
            const { data, error } = await supabase
              .from('tickets')
              .select('*, users!tickets_user_id_fkey(email)')
              .in('event_id', eventIds)
              .order('purchase_date', { ascending: false })
              .limit(PAGE_SIZE);

            if (error) throw error;

            allTickets = (data || []).map(transformTicket);
          }
          setHasMore(false);
        }
      }

      setTickets(allTickets);
      groupTicketsByEvent(allTickets);

      // Cache the results
      if (reset && allTickets.length > 0) {
        const cacheKey = getCacheKey(user.uid, user.role, user.venueId);
        setCache(cacheKey, allTickets);
      }
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
  }, [loadingMore, hasMore, currentOffset, tickets]);

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
        ticket.userEmail?.toLowerCase().includes(searchLower)
      )
    );
  });

  const filteredTickets = tickets.filter(t => {
    if (!search) return true;
    const searchLower = search.toLowerCase();
    return (
      t.userEmail?.toLowerCase().includes(searchLower) ||
      t.eventName?.toLowerCase().includes(searchLower)
    );
  });

  const markUsed = async (ticket: Ticket) => {
    if (ticket.is_used) return;
    try {
      const { error } = await supabase
        .from('tickets')
        .update({
          status: 'used',
          used_at: new Date().toISOString()
        })
        .eq('ticket_id', ticket.id);

      if (error) throw error;

      toast.success("Ticket marked as used!");
      // Clear cache and reload
      if (user) {
        const cacheKey = getCacheKey(user.uid, user.role, user.venueId);
        cache.delete(cacheKey);
      }
      loadTickets(true, true);
    } catch (e: any) {
      toast.error("Error updating ticket: " + e.message);
    }
  };

  const cancelTicket = async (ticket: Ticket) => {
    try {
      const { error } = await supabase
        .from('tickets')
        .update({
          status: 'cancelled',
          cancelled_at: new Date().toISOString(),
          cancelled_by: user?.email || 'admin'
        })
        .eq('ticket_id', ticket.id);

      if (error) throw error;

      toast.success("Ticket cancelled successfully!");
      // Clear cache and reload
      if (user) {
        const cacheKey = getCacheKey(user.uid, user.role, user.venueId);
        cache.delete(cacheKey);
      }
      loadTickets(true, true);
    } catch (e: any) {
      toast.error("Error cancelling ticket: " + e.message);
    }
  };

  const deleteTicket = async (ticket: Ticket, permanent: boolean = false) => {
    try {
      // For siteAdmins with permanent deletion enabled, actually delete from database
      // For used tickets, siteAdmins can permanently delete them
      if (permanent && user?.role === 'siteAdmin' && ticket.is_used) {
        const { error } = await supabase
          .from('tickets')
          .delete()
          .eq('ticket_id', ticket.id);

        if (error) throw error;

        toast.success("Ticket permanently deleted from database!");
      } else {
        // Mark as deleted instead of actually deleting
        const { error } = await supabase
          .from('tickets')
          .update({
            status: 'deleted',
            deleted_at: new Date().toISOString(),
            deleted_by: user?.email || 'admin'
          })
          .eq('ticket_id', ticket.id);

        if (error) throw error;

        toast.success("Ticket marked as deleted!");
      }

      // Clear cache and reload
      if (user) {
        const cacheKey = getCacheKey(user.uid, user.role, user.venueId);
        const statsCacheKey = `stats_${user.uid}_${user.role}_${user.venueId || 'all'}`;
        cache.delete(cacheKey);
        cache.delete(statsCacheKey);
      }
      loadTickets(true, true);
      loadStats();
    } catch (e: any) {
      toast.error("Error deleting ticket: " + e.message);
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
    // Clear cache on manual refresh
    if (user) {
      const cacheKey = getCacheKey(user.uid, user.role, user.venueId);
      const statsCacheKey = `stats_${user.uid}_${user.role}_${user.venueId || 'all'}`;
      cache.delete(cacheKey);
      cache.delete(statsCacheKey);
    }
    loadTickets(true, true);
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
    cancelTicket,
    deleteTicket,
    toggleEventExpansion,
    loadTickets: refreshData,
    loadMore,
    stats,
    dateFilter,
    changeDateFilter
  };
}
