import { useEffect, useState, useRef } from "react";
import { supabase } from "@/lib/supabase";
import { useAuth } from "@/components/useAuth";
import { toast } from "sonner";

// Cache configuration
const CACHE_TTL = 5 * 60 * 1000; // 5 minutes
const cache = new Map<string, { data: any; timestamp: number }>();

function getCacheKey(userId: string, role: string, venueId?: string | null): string {
  return `overview_${userId}_${role}_${venueId || 'all'}`;
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

export type Ticket = {
  id: string;
  user_id: string;
  user_email?: string;
  event_name: string;
  event_id?: string;
  venue_id?: string;
  total_price: number;
  purchase_date: string;
  status: string;
  used_at?: string;
  // Legacy camelCase for backward compatibility
  userID?: string;
  userEmail?: string;
  eventName?: string;
  eventId?: string;
  venueId?: string;
  totalPrice?: number;
  purchaseDate?: string;
  usedAt?: string;
};

export type UserStats = {
  userID: string;
  email: string;
  ticketCount: number;
  totalSpent: number;
  events: string[];
};

export type EventStats = {
  eventId?: string;
  eventName: string;
  ticketCount: number;
  revenue: number;
  usedTickets: number;
  status?: string;
  startTime?: Date | null;
  venueName?: string;
};

export type DailySales = {
  date: string;
  tickets: number;
  revenue: number;
};

export type OverviewMetrics = {
  totalTickets: number;
  totalUsers: number;
  totalRevenue: number;
  usedTickets: number;
  usageRate: number;
  avgRevenuePerUser: number;
  totalEvents: number;
  activeEvents: number;
};

export function useOverviewData() {
  const { user, loading: authLoading } = useAuth();
  const [tickets, setTickets] = useState<Ticket[]>([]);
  const [users, setUsers] = useState<UserStats[]>([]);
  const [eventStats, setEventStats] = useState<EventStats[]>([]);
  const [dailySales, setDailySales] = useState<DailySales[]>([]);
  const [loading, setLoading] = useState(true);
  const daysToShow = 90;
  const hasLoadedRef = useRef(false);

  useEffect(() => {
    if (!authLoading && user) {
      loadTicketsAndUsers();
    }
  }, [user, authLoading]);

  async function loadTicketsAndUsers() {
    if (!user) return;

    // Check cache first
    const cacheKey = getCacheKey(user.uid, user.role, user.venueId);
    const cachedData = getFromCache<{
      tickets: Ticket[];
      users: UserStats[];
      eventStats: EventStats[];
      dailySales: DailySales[];
    }>(cacheKey);

    if (cachedData && hasLoadedRef.current) {
      // Use cached data and skip loading state
      setTickets(cachedData.tickets);
      setUsers(cachedData.users);
      setEventStats(cachedData.eventStats);
      setDailySales(cachedData.dailySales);
      setLoading(false);
      return;
    }

    setLoading(true);
    try {
      let allTickets: Ticket[] = [];

      const transformTicket = (data: any) => {
        const totalPrice = typeof data.total_price === "number"
          ? data.total_price
          : typeof data.ticket_price === "number"
          ? data.ticket_price
          : 0;

        return {
          id: data.id,
          user_id: data.user_id,
          user_email: data.user_email,
          event_name: data.event_name,
          event_id: data.event_id,
          venue_id: data.venue_id,
          total_price: totalPrice,
          purchase_date: data.purchase_date,
          status: data.status || (data.is_used ? "used" : "confirmed"),
          used_at: data.used_at,
          // Legacy camelCase for backward compatibility
          userID: data.user_id,
          userEmail: data.user_email,
          eventName: data.event_name,
          eventId: data.event_id,
          venueId: data.venue_id,
          totalPrice: totalPrice,
          purchaseDate: data.purchase_date,
          usedAt: data.used_at,
        } as Ticket;
      };

      if (user.role === "siteAdmin") {
        // Site admin sees all tickets
        const { data, error } = await supabase
          .from('tickets')
          .select('*');

        if (error) throw error;
        allTickets = (data || []).map(transformTicket);

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
            .in('venue_id', venueIds);

          if (eventsError) throw eventsError;

          const eventIds = eventsData?.map((e: any) => e.id) || [];

          if (eventIds.length > 0) {
            // Query tickets for these events
            const { data, error } = await supabase
              .from('tickets')
              .select('*')
              .in('event_id', eventIds);

            if (error) throw error;
            allTickets = (data || []).map(transformTicket);
          }
        }

      } else if (user.role === "venueAdmin" || user.role === "subAdmin") {
        if (!user.venueId) {
          toast.error("No venue assigned to your account");
          setLoading(false);
          return;
        }

        // Query events for this venue first
        const { data: eventsData, error: eventsError } = await supabase
          .from('events')
          .select('id')
          .eq('venue_id', user.venueId);

        if (eventsError) throw eventsError;

        const eventIds = eventsData?.map((e: any) => e.id) || [];

        if (eventIds.length > 0) {
          // Query tickets for this venue's events
          const { data, error } = await supabase
            .from('tickets')
            .select('*')
            .in('event_id', eventIds);

          if (error) throw error;
          allTickets = (data || []).map(transformTicket);
        }
      } else {
        setLoading(false);
        return;
      }

      setTickets(allTickets);
      const userStatsData = processUserStats(allTickets);
      const aggregatedLoaded = await loadAggregatedEventStats();
      let eventStatsData: EventStats[];
      if (!aggregatedLoaded) {
        eventStatsData = processEventStats(allTickets);
      } else {
        eventStatsData = eventStats; // Use existing state if aggregated loaded
      }
      const dailySalesData = processDailySales(allTickets);

      // Cache the results
      const cacheKey = getCacheKey(user.uid, user.role, user.venueId);
      setCache(cacheKey, {
        tickets: allTickets,
        users: userStatsData,
        eventStats: eventStatsData,
        dailySales: dailySalesData
      });
      hasLoadedRef.current = true;
    } catch (error: any) {
      toast.error("Failed to load overview: " + error.message);
    } finally {
      setLoading(false);
    }
  }

  async function loadAggregatedEventStats() {
    try {
      // Try to load from eventStats table/view if it exists
      // Otherwise return false to fall back to client-side aggregation
      let query = supabase.from('eventStats').select('*');

      if (user?.role === "organiser") {
        // Organisers: Filter by their assigned venues
        const { data: organiserVenuesData } = await supabase
          .from('organizer_venues')
          .select('venue_id')
          .eq('organizer_id', user.uid);

        const venueIds = organiserVenuesData?.map((ov: any) => ov.venue_id) || [];
        if (venueIds.length === 0) return false;

        query = query.in('venue_id', venueIds);

      } else if (user?.role === "venueAdmin" || user?.role === "subAdmin") {
        if (!user.venueId) return false;
        query = query.eq('venue_id', user.venueId);
      }

      const { data, error } = await query;

      if (error || !data || data.length === 0) {
        // Table/view doesn't exist or is empty, fall back to client-side aggregation
        return false;
      }

      const aggregated: EventStats[] = data.map((row: any) => ({
        eventId: row.event_id || row.id,
        eventName: row.event_name || row.name || row.id,
        ticketCount: row.tickets_sold || row.ticket_count || 0,
        revenue: row.total_revenue || row.revenue || 0,
        usedTickets: row.tickets_used || row.used_tickets || 0,
        status: row.status,
        startTime: row.start_time ? new Date(row.start_time) : null,
        venueName: row.venue_name,
      }));

      aggregated.sort((a, b) => (b.revenue || 0) - (a.revenue || 0));
      setEventStats(aggregated);
      return true;
    } catch (error) {
      console.warn("Unable to load aggregated event stats, using client-side aggregation", error);
      return false;
    }
  }

  function processUserStats(allTickets: Ticket[]): UserStats[] {
    const userMap: Record<string, UserStats> = {};
    allTickets.forEach((ticket) => {
      if (!userMap[ticket.user_id]) {
        userMap[ticket.user_id] = {
          userID: ticket.user_id,
          email: ticket.userEmail || "Unknown",
          ticketCount: 0,
          totalSpent: 0,
          events: [],
        };
      }
      const target = userMap[ticket.user_id];
      target.ticketCount++;
      target.totalSpent += ticket.totalPrice || 0;
      if (ticket.eventName && !target.events.includes(ticket.eventName)) {
        target.events.push(ticket.eventName);
      }
    });
    const userStatsArray = Object.values(userMap);
    setUsers(userStatsArray);
    return userStatsArray;
  }

  function processEventStats(allTickets: Ticket[]): EventStats[] {
    const eventMap: Record<string, EventStats> = {};
    allTickets.forEach((ticket) => {
      if (!eventMap[ticket.event_name]) {
        eventMap[ticket.event_name] = {
          eventName: ticket.event_name,
          ticketCount: 0,
          revenue: 0,
          usedTickets: 0,
        };
      }
      const event = eventMap[ticket.event_name];
      event.ticketCount++;
      event.revenue += ticket.totalPrice || 0;
      if (ticket.status?.toLowerCase() === "used") {
        event.usedTickets++;
      }
    });
    const eventStatsArray = Object.values(eventMap).sort((a, b) => b.revenue - a.revenue);
    setEventStats(eventStatsArray);
    return eventStatsArray;
  }

  function processDailySales(allTickets: Ticket[]): DailySales[] {
    const salesMap: Record<string, DailySales> = {};
    const now = new Date();

    for (let i = 0; i < daysToShow; i++) {
      const date = new Date(now);
      date.setDate(date.getDate() - i);
      const key = date.toISOString().split("T")[0];
      salesMap[key] = {
        date: key,
        tickets: 0,
        revenue: 0,
      };
    }

    allTickets.forEach((ticket) => {
      const purchaseDateStr = ticket.purchase_date || ticket.purchaseDate;
      if (purchaseDateStr) {
        let purchaseDate: Date;

        // Handle various date formats (ISO string, Date object, Firebase Timestamp)
        if (typeof purchaseDateStr === 'string') {
          purchaseDate = new Date(purchaseDateStr);
        } else if ((purchaseDateStr as any) instanceof Date) {
          purchaseDate = purchaseDateStr as any;
        } else if ((purchaseDateStr as any).toDate) {
          purchaseDate = (purchaseDateStr as any).toDate();
        } else {
          purchaseDate = new Date(purchaseDateStr as any);
        }

        const key = purchaseDate.toISOString().split("T")[0];

        if (salesMap[key]) {
          salesMap[key].tickets++;
          salesMap[key].revenue += ticket.total_price || ticket.totalPrice || 0;
        }
      }
    });

    const dailySalesArray = Object.values(salesMap)
      .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime())
      .map((day) => ({
        ...day,
        date: new Date(day.date).toLocaleDateString("en-US", {
          month: "short",
          day: "numeric",
        }),
      }));

    setDailySales(dailySalesArray);
    return dailySalesArray;
  }

  const activeEvents = eventStats.filter((event) => (event.status || "").toLowerCase() === "active").length;

  const metrics: OverviewMetrics = {
    totalTickets: tickets.length,
    totalUsers: users.length,
    totalRevenue: users.reduce((sum, user) => sum + user.totalSpent, 0),
    usedTickets: tickets.filter((ticket) => ticket.status?.toLowerCase() === "used").length,
    usageRate:
      tickets.length > 0
        ? (tickets.filter((ticket) => ticket.status?.toLowerCase() === "used").length / tickets.length) * 100
        : 0,
    avgRevenuePerUser:
      users.length > 0
        ? users.reduce((sum, user) => sum + user.totalSpent, 0) / users.length
        : 0,
    totalEvents: eventStats.length,
    activeEvents,
  };

  return {
    user,
    authLoading,
    loading,
    tickets,
    users,
    eventStats,
    dailySales,
    metrics,
  };
}
