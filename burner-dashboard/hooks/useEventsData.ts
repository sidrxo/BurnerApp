import { useEffect, useMemo, useState } from "react";
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  setDoc,
  Timestamp,
  updateDoc,
  where,
  writeBatch,
} from "firebase/firestore";
import { ref, uploadBytesResumable, getDownloadURL, deleteObject } from "firebase/storage";
import { toast } from "sonner";

import { useAuth } from "@/components/useAuth";
import { db, storage } from "@/lib/firebase";
import {
  EVENT_CATEGORY_OPTIONS,
  EVENT_STATUS_OPTIONS,
  EventStatus,
} from "@/lib/constants";

export interface Event {
  id: string;
  name: string;
  description?: string | null;
  venue?: string;
  venueId?: string | null;
  startTime?: Timestamp;
  endTime?: Timestamp | null;
  price: number;
  maxTickets: number;
  ticketsSold: number;
  isFeatured?: boolean;
  imageUrl?: string | null;
  status?: EventStatus | string | null;
  category?: string | null;
  tags?: string[];
  coordinates?: { latitude: number; longitude: number } | null;
  organizerId?: string | null;
  date?: Timestamp; // legacy support
  createdAt?: Timestamp;
  updatedAt?: Timestamp;
}

export interface Venue {
  id: string;
  name: string;
  coordinates?: { latitude: number; longitude: number } | null;
}

export interface EventFormData {
  id: string;
  name: string;
  description: string;
  venueId: string;
  startDateTime: string;
  endDateTime: string;
  price: number;
  maxTickets: number;
  isFeatured: boolean;
  status: EventStatus;
  category: string;
  tag: string;
}

function timestampToInputValue(timestamp?: Timestamp | null) {
  if (!timestamp) return "";
  try {
    return timestamp.toDate().toISOString().slice(0, 16);
  } catch {
    return "";
  }
}

function toDate(value?: Timestamp | { seconds: number } | null) {
  if (!value) return undefined;
  try {
    if (value instanceof Timestamp) return value.toDate();
    if (typeof value.seconds === "number") {
      return new Date(value.seconds * 1000);
    }
  } catch {
    /* ignore */
  }
  return undefined;
}

function normaliseTag(tag?: string | null) {
  if (!tag) return "";
  return tag.trim().toLowerCase();
}

export function useEventsData() {
  const { user, loading: authLoading } = useAuth();
  const [events, setEvents] = useState<Event[]>([]);
  const [venues, setVenues] = useState<Venue[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [tagFilter, setTagFilter] = useState<string>("all");

  useEffect(() => {
    if (!authLoading && user) {
      loadEvents();
      if (user.role === "siteAdmin") {
        loadVenues();
      }
    }
  }, [user, authLoading]);

  const loadVenues = async () => {
    try {
      const snapshot = await getDocs(collection(db, "venues"));
      const loadedVenues: Venue[] = snapshot.docs.map((doc) => {
        const data = doc.data();
        let coordinates = null;
        if (data.coordinates) {
          coordinates = {
            latitude: data.coordinates.latitude,
            longitude: data.coordinates.longitude,
          };
        }
        return {
          id: doc.id,
          name: data.name ?? doc.id,
          coordinates,
        };
      });
      setVenues(loadedVenues);
    } catch (error) {
      console.error("Error loading venues:", error);
      toast.error("Failed to load venues");
    }
  };

  const loadEvents = async () => {
    if (!user) return;
    setLoading(true);

    try {
      let eventsQuery;

      if (user.role === "siteAdmin") {
        eventsQuery = query(collection(db, "events"), orderBy("startTime", "desc"));
      } else if (user.role === "venueAdmin" || user.role === "subAdmin") {
        if (!user.venueId) {
          toast.error("No venue assigned to your account");
          setEvents([]);
          setLoading(false);
          return;
        }
        eventsQuery = query(
          collection(db, "events"),
          where("venueId", "==", user.venueId),
          orderBy("startTime", "desc")
        );
      } else {
        setEvents([]);
        setLoading(false);
        return;
      }

      const snap = await getDocs(eventsQuery);
      const list: Event[] = snap.docs.map((d) => ({
        id: d.id,
        ...(d.data() as any),
      }));

      list.sort((a, b) => {
        const featuredSort = Number(!!b.isFeatured) - Number(!!a.isFeatured);
        if (featuredSort !== 0) return featuredSort;
        const aDate = toDate(a.startTime) ?? toDate(a.date) ?? new Date(0);
        const bDate = toDate(b.startTime) ?? toDate(b.date) ?? new Date(0);
        return bDate.getTime() - aDate.getTime();
      });

      setEvents(list);
    } catch (error: any) {
      console.error("Error loading events:", error);
      toast.error(`Failed to load events: ${error.message ?? "Unknown error"}`);
    } finally {
      setLoading(false);
    }
  };

  const availableTags = useMemo(() => {
    const tagSet = new Set<string>();
    events.forEach((event) => {
      const tags = event.tags ?? [];
      if (tags.length) {
        tagSet.add(normaliseTag(tags[0]));
      }
    });
    return Array.from(tagSet).filter(Boolean);
  }, [events]);

  const filtered = useMemo(() => {
    const s = search.trim().toLowerCase();

    return events.filter((event) => {
      const matchesSearch =
        !s ||
        event.name?.toLowerCase().includes(s) ||
        event.venue?.toLowerCase().includes(s) ||
        event.description?.toLowerCase().includes(s) ||
        event.tags?.some((tag) => tag.toLowerCase().includes(s));

      if (!matchesSearch) return false;

      if (statusFilter !== "all") {
        const resolvedStatus = (event.status ?? deriveStatus(event)).toLowerCase();
        if (resolvedStatus !== statusFilter.toLowerCase()) return false;
      }

      if (tagFilter !== "all") {
        const primaryTag = normaliseTag(event.tags?.[0]);
        if (primaryTag !== tagFilter) return false;
      }

      return true;
    });
  }, [events, search, statusFilter, tagFilter]);

  const onToggleFeatured = async (ev: Event) => {
    if (!user || user.role !== "siteAdmin") {
      toast.error("Only site administrators can manage featured events");
      return;
    }

    try {
      await updateDoc(doc(db, "events", ev.id), {
        isFeatured: !ev.isFeatured,
        updatedAt: Timestamp.now(),
      });
      setEvents((prev) =>
        prev.map((event) =>
          event.id === ev.id ? { ...event, isFeatured: !event.isFeatured } : event
        )
      );
      toast.success(`Event ${!ev.isFeatured ? "featured" : "unfeatured"}`);
    } catch (error: any) {
      toast.error(error.message || "Failed to toggle feature");
    }
  };

  const onDelete = async (ev: Event) => {
    try {
      const ticketsSnap = await getDocs(collection(db, "events", ev.id, "tickets"));
      if (!ticketsSnap.empty) {
        const batch = writeBatch(db);
        ticketsSnap.forEach((ticket) => batch.delete(ticket.ref));
        await batch.commit();
      }

      if (ev.imageUrl) {
        try {
          await deleteObject(ref(storage, ev.imageUrl));
        } catch (storageError) {
          console.warn("Unable to delete existing image", storageError);
        }
      }

      await deleteDoc(doc(db, "events", ev.id));
      setEvents((prev) => prev.filter((event) => event.id !== ev.id));
      toast.success("Event deleted successfully");
    } catch (error: any) {
      toast.error(error.message || "Failed to delete event");
    }
  };

  const getEventStatus = (ev: Event) => {
    const resolved = (ev.status ?? deriveStatus(ev))?.toString().toLowerCase();
    switch (resolved) {
      case "draft":
        return { status: "draft", label: "Draft", variant: "secondary" as const };
      case "scheduled":
        return { status: "scheduled", label: "Scheduled", variant: "outline" as const };
      case "active":
        return { status: "active", label: "Active", variant: "default" as const };
      case "soldout":
      case "sold_out":
        return { status: "soldOut", label: "Sold Out", variant: "destructive" as const };
      case "completed":
      case "past":
        return { status: "completed", label: "Completed", variant: "secondary" as const };
      case "cancelled":
        return { status: "cancelled", label: "Cancelled", variant: "destructive" as const };
      default: {
        const isSoldOut = (ev.ticketsSold ?? 0) >= (ev.maxTickets ?? 0);
        if (isSoldOut) {
          return { status: "soldOut", label: "Sold Out", variant: "destructive" as const };
        }
        return { status: "active", label: "Active", variant: "default" as const };
      }
    }
  };

  const getTicketProgress = (ev: Event) => {
    const sold = ev.ticketsSold || 0;
    const max = ev.maxTickets || 1;
    return Math.min((sold / max) * 100, 100);
  };

  return {
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
    availableTags,
    filtered,
    onToggleFeatured,
    onDelete,
    getEventStatus,
    getTicketProgress,
    loadEvents,
    setEvents,
  };
}

function deriveStatus(ev: Event): EventStatus {
  const now = new Date();
  const start = toDate(ev.startTime) ?? toDate(ev.date);
  const end = toDate(ev.endTime);

  if (!start) {
    return "draft";
  }

  if (end && end < now) {
    return "completed";
  }

  if (start > now) {
    return "scheduled";
  }

  if ((ev.ticketsSold ?? 0) >= (ev.maxTickets ?? 0)) {
    return "soldOut";
  }

  return "active";
}

export function useEventForm(
  existing: Event | null,
  user: any,
  venues: Venue[],
  onSaved: (event: Event) => void,
  onClose: () => void,
  availableTags: string[] = []
) {
  const isEdit = !!existing;
  const suggestedTags = useMemo(
    () => Array.from(new Set([...availableTags.map(normaliseTag)])).filter(Boolean),
    [availableTags]
  );
  const [form, setForm] = useState<EventFormData>({
    id: existing?.id ?? "",
    name: existing?.name ?? "",
    description: existing?.description ?? "",
    venueId: existing?.venueId ?? (user.role === "siteAdmin" ? "" : user.venueId || ""),
    startDateTime: timestampToInputValue(existing?.startTime ?? existing?.date ?? null),
    endDateTime: timestampToInputValue(existing?.endTime ?? null),
    price: existing?.price ?? 0,
    maxTickets: existing?.maxTickets ?? 0,
    isFeatured: user.role === "siteAdmin" ? !!existing?.isFeatured : false,
    status: (existing?.status as EventStatus) || deriveStatus(existing || ({} as Event)),
    category: existing?.category || EVENT_CATEGORY_OPTIONS[0].value,
    tag: normaliseTag(existing?.tags?.[0]) || "",
  });
  const [file, setFile] = useState<File | null>(null);
  const [progress, setProgress] = useState(0);
  const [saving, setSaving] = useState(false);

  async function uploadImageIfAny(eventId: string) {
    if (!file) return existing?.imageUrl ?? null;

    const allowed = ["image/jpeg", "image/jpg", "image/png", "image/gif"];
    if (!allowed.includes(file.type)) throw new Error("Invalid file type");
    if (file.size > 5 * 1024 * 1024) throw new Error("File too large (max 5MB)");

    const storagePath = `event-images/${eventId}/${Date.now()}_${file.name}`;
    const storageRef = ref(storage, storagePath);
    const task = uploadBytesResumable(storageRef, file);

    const url: string = await new Promise((resolve, reject) => {
      task.on(
        "state_changed",
        (snapshot) => {
          setProgress((snapshot.bytesTransferred / snapshot.totalBytes) * 100);
        },
        reject,
        async () => resolve(await getDownloadURL(task.snapshot.ref))
      );
    });

    if (existing?.imageUrl && existing.imageUrl !== url) {
      try {
        await deleteObject(ref(storage, existing.imageUrl));
      } catch {
        /* ignore */
      }
    }

    return url;
  }

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();

    try {
      setSaving(true);

      if (!form.name || !form.startDateTime) {
        throw new Error("Please fill all required fields");
      }

      let selectedVenueId = "";
      let selectedVenueName = "";

      if (user.role === "siteAdmin") {
        if (!form.venueId) {
          throw new Error("Please select a venue");
        }
        selectedVenueId = form.venueId;
        const selectedVenue = venues.find((v) => v.id === form.venueId);
        selectedVenueName = selectedVenue?.name || "Unknown Venue";
      } else {
        if (!user.venueId) {
          throw new Error("No venue assigned to your account");
        }
        selectedVenueId = user.venueId;
        try {
          const venueDoc = await getDoc(doc(db, "venues", user.venueId));
          selectedVenueName = venueDoc.exists() ? venueDoc.data().name : "Unknown Venue";
        } catch {
          selectedVenueName = "Unknown Venue";
        }
      }

      const start = Timestamp.fromDate(new Date(form.startDateTime));
      const end = form.endDateTime ? Timestamp.fromDate(new Date(form.endDateTime)) : null;

      if (end && end.toMillis() <= start.toMillis()) {
        throw new Error("End time must be after start time");
      }

      const url = await uploadImageIfAny(isEdit ? existing!.id : form.id);
      const tags = form.tag ? [normaliseTag(form.tag)] : [];

      // Get coordinates from venue
      let coordinates: { latitude: number; longitude: number } | null = null;
      try {
        const venueDoc = await getDoc(doc(db, "venues", selectedVenueId));
        if (venueDoc.exists()) {
          const venueData = venueDoc.data();
          if (venueData.coordinates) {
            coordinates = {
              latitude: venueData.coordinates.latitude,
              longitude: venueData.coordinates.longitude,
            };
          }
        }
      } catch (error) {
        console.warn("Failed to fetch venue coordinates:", error);
      }

      if (isEdit) {
        const updatePayload: Partial<Event> & { updatedAt: Timestamp } = {
          name: form.name,
          description: form.description || null,
          venue: selectedVenueName,
          venueId: selectedVenueId,
          startTime: start,
          endTime: end,
          date: start,
          price: Number(form.price),
          maxTickets: Number(form.maxTickets),
          status: form.status,
          category: form.category,
          tags,
          coordinates,
          updatedAt: Timestamp.now(),
        };

        if (url) {
          (updatePayload as any).imageUrl = url;
        }

        if (user.role === "siteAdmin") {
          updatePayload.isFeatured = form.isFeatured;
        }

        await updateDoc(doc(db, "events", existing!.id), updatePayload as any);

        onSaved({
          ...(existing as Event),
          ...updatePayload,
          imageUrl: url ?? existing?.imageUrl ?? null,
        } as Event);
        toast.success("Event updated successfully");
      } else {
        if (!form.id.trim()) {
          throw new Error("Event ID is required");
        }

        const payload: Event = {
          id: form.id,
          name: form.name,
          description: form.description,
          venue: selectedVenueName,
          venueId: selectedVenueId,
          startTime: start,
          endTime: end,
          date: start,
          price: Number(form.price),
          maxTickets: Number(form.maxTickets),
          ticketsSold: 0,
          isFeatured: user.role === "siteAdmin" ? form.isFeatured : false,
          imageUrl: url ?? null,
          status: form.status,
          category: form.category,
          tags,
          coordinates,
          organizerId: user.uid,
          createdAt: Timestamp.now(),
        };

        await setDoc(doc(db, "events", form.id), {
          name: payload.name,
          description: payload.description || null,
          venue: payload.venue,
          venueId: payload.venueId,
          startTime: payload.startTime,
          endTime: payload.endTime ?? null,
          date: payload.date,
          price: payload.price,
          maxTickets: payload.maxTickets,
          ticketsSold: 0,
          isFeatured: payload.isFeatured,
          imageUrl: payload.imageUrl,
          status: payload.status,
          category: payload.category,
          tags: payload.tags,
          coordinates: payload.coordinates ?? null,
          organizerId: payload.organizerId,
          createdAt: payload.createdAt,
          createdBy: user.uid,
        });

        onSaved(payload);
        toast.success("Event created successfully");
      }

      onClose();
    } catch (error: any) {
      toast.error(error.message || "Save failed");
    } finally {
      setSaving(false);
      setProgress(0);
    }
  }

  const resetForm = () => {
    setForm({
      id: existing?.id ?? "",
      name: existing?.name ?? "",
      description: existing?.description ?? "",
      venueId: existing?.venueId ?? (user.role === "siteAdmin" ? "" : user.venueId || ""),
      startDateTime: timestampToInputValue(existing?.startTime ?? existing?.date ?? null),
      endDateTime: timestampToInputValue(existing?.endTime ?? null),
      price: existing?.price ?? 0,
      maxTickets: existing?.maxTickets ?? 0,
      isFeatured: user.role === "siteAdmin" ? !!existing?.isFeatured : false,
      status: (existing?.status as EventStatus) || deriveStatus(existing || ({} as Event)),
      category: existing?.category || EVENT_CATEGORY_OPTIONS[0].value,
      tag: normaliseTag(existing?.tags?.[0]) || "",
    });
    setFile(null);
    setProgress(0);
  };

  return {
    form,
    setForm,
    file,
    setFile,
    progress,
    saving,
    onSubmit,
    resetForm,
    isEdit,
    statusOptions: EVENT_STATUS_OPTIONS,
    categoryOptions: EVENT_CATEGORY_OPTIONS,
    tagOptions: suggestedTags,
  };
}
