import { useEffect, useState } from "react";
import { collection, collectionGroup, getDocs, query, where } from "firebase/firestore";

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
  totalPrice: number;
  purchaseDate: any;
  status: string;
  usedAt?: any;
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

  useEffect(() => {
    if (!authLoading && user) {
      loadTicketsAndUsers();
    }
  }, [user, authLoading]);

  async function loadTicketsAndUsers() {
    if (!user) return;

    setLoading(true);
    try {
      let allTickets: Ticket[] = [];

      const transformTicket = (doc: any) => {
        const data = doc.data();
        return {
          id: doc.id,
          ...data,
          totalPrice:
            typeof data.totalPrice === "number"
              ? data.totalPrice
              : typeof data.ticketPrice === "number"
              ? data.ticketPrice
              : 0,
          status: data.status || (data.isUsed ? "used" : "confirmed"),
          usedAt: data.usedAt,
        } as Ticket;
      };

      if (user.role === "siteAdmin") {
        const ticketsSnap = await getDocs(collectionGroup(db, "tickets"));
        allTickets = ticketsSnap.docs.map(transformTicket);
      } else if (user.role === "venueAdmin" || user.role === "subAdmin") {
        if (!user.venueId) {
          toast.error("No venue assigned to your account");
          setLoading(false);
          return;
        }
        const ticketsSnap = await getDocs(collectionGroup(db, "tickets"));
        allTickets = ticketsSnap.docs
          .map(transformTicket)
          .filter((ticket) => ticket.venueId === user.venueId);
      } else {
        setLoading(false);
        return;
      }

      setTickets(allTickets);
      processUserStats(allTickets);
      const aggregatedLoaded = await loadAggregatedEventStats();
      if (!aggregatedLoaded) {
        processEventStats(allTickets);
      }
      processDailySales(allTickets);
    } catch (error: any) {
      toast.error("Failed to load overview: " + error.message);
    } finally {
      setLoading(false);
    }
  }

  async function loadAggregatedEventStats() {
    try {
      let statsQuery;
      if (user?.role === "siteAdmin") {
        statsQuery = collection(db, "eventStats");
      } else if (user?.venueId) {
        statsQuery = query(collection(db, "eventStats"), where("venueId", "==", user.venueId));
      } else {
        return false;
      }

      const statsSnap = await getDocs(statsQuery);
      if (statsSnap.empty) {
        return false;
      }

      const aggregated: EventStats[] = statsSnap.docs.map((doc) => {
        const data = doc.data() as any;
        return {
          eventId: doc.id,
          eventName: data.eventName || doc.id,
          ticketCount: data.totalTickets || 0,
          revenue: data.totalRevenue || 0,
          usedTickets: data.usedTickets || 0,
          status: data.status,
          startTime: data.startTime?.toDate ? data.startTime.toDate() : data.startTime || null,
          venueName: data.venueName,
        };
      });

      aggregated.sort((a, b) => (b.revenue || 0) - (a.revenue || 0));
      setEventStats(aggregated);
      return true;
    } catch (error) {
      console.warn("Unable to load aggregated event stats", error);
      return false;
    }
  }

  function processUserStats(allTickets: Ticket[]) {
    const userMap: Record<string, UserStats> = {};
    allTickets.forEach((ticket) => {
      if (!userMap[ticket.userID]) {
        userMap[ticket.userID] = {
          userID: ticket.userID,
          email: ticket.userEmail || "Unknown",
          ticketCount: 0,
          totalSpent: 0,
          events: [],
        };
      }
      const target = userMap[ticket.userID];
      target.ticketCount++;
      target.totalSpent += ticket.totalPrice || 0;
      if (ticket.eventName && !target.events.includes(ticket.eventName)) {
        target.events.push(ticket.eventName);
      }
    });
    setUsers(Object.values(userMap));
  }

  function processEventStats(allTickets: Ticket[]) {
    const eventMap: Record<string, EventStats> = {};
    allTickets.forEach((ticket) => {
      if (!eventMap[ticket.eventName]) {
        eventMap[ticket.eventName] = {
          eventName: ticket.eventName,
          ticketCount: 0,
          revenue: 0,
          usedTickets: 0,
        };
      }
      const event = eventMap[ticket.eventName];
      event.ticketCount++;
      event.revenue += ticket.totalPrice || 0;
      if (ticket.status?.toLowerCase() === "used") {
        event.usedTickets++;
      }
    });
    setEventStats(Object.values(eventMap).sort((a, b) => b.revenue - a.revenue));
  }

  function processDailySales(allTickets: Ticket[]) {
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
      if (ticket.purchaseDate) {
        let purchaseDate: Date;

        if (ticket.purchaseDate.toDate) {
          purchaseDate = ticket.purchaseDate.toDate();
        } else if (ticket.purchaseDate instanceof Date) {
          purchaseDate = ticket.purchaseDate;
        } else {
          purchaseDate = new Date(ticket.purchaseDate);
        }

        const key = purchaseDate.toISOString().split("T")[0];

        if (salesMap[key]) {
          salesMap[key].tickets++;
          salesMap[key].revenue += ticket.totalPrice || 0;
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
