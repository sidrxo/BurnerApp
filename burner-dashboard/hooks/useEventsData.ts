import { useEffect, useMemo, useState, useCallback } from "react";
import { toast } from "sonner";

import { useAuth } from "@/components/useAuth";
import { supabase } from "@/lib/supabase";
import {
  EVENT_STATUS_OPTIONS,
  EventStatus,
} from "@/lib/constants";

export interface Event {
  id: string;
  name: string;
  description?: string | null;
  venue?: string;
  venue_id?: string | null;
  venueId?: string | null; // Legacy camelCase
  start_time?: string;
  startTime?: string; // Legacy camelCase
  end_time?: string | null;
  endTime?: string | null; // Legacy camelCase
  price: number;
  max_tickets: number;
  maxTickets?: number; // Legacy camelCase
  tickets_sold: number;
  ticketsSold?: number; // Legacy camelCase
  is_featured?: boolean;
  isFeatured?: boolean; // Legacy camelCase
  featured_priority?: number;
  featuredPriority?: number; // Legacy camelCase
  image_url?: string | null;
  imageUrl?: string | null; // Legacy camelCase
  status?: EventStatus | string | null;
  category?: string | null;
  tags?: string[];
  coordinates?: { latitude: number; longitude: number } | null;
  organizer_id?: string | null;
  organizerId?: string | null; // Legacy camelCase
  created_at?: string;
  createdAt?: string; // Legacy camelCase
  updated_at?: string;
  updatedAt?: string; // Legacy camelCase
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
  tag: string;
}

function timestampToInputValue(timestamp?: string | null) {
  if (!timestamp) return "";
  try {
    return new Date(timestamp).toISOString().slice(0, 16);
  } catch {
    return "";
  }
}

function toDate(value?: string | null) {
  if (!value) return undefined;
  try {
    return new Date(value);
  } catch {
    return undefined;
  }
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
  const [sortBy, setSortBy] = useState<string>("date-desc");
  const [tagsFromCollection, setTagsFromCollection] = useState<string[]>([]);

  // Cache for venue lookups (performance improvement)
  const [venueCache, setVenueCache] = useState<Map<string, string>>(new Map());

  useEffect(() => {
    if (!authLoading && user) {
      loadEvents();
      loadTagsFromCollection();
      if (user.role === "siteAdmin") {
        loadVenues();
      }
    }
  }, [user, authLoading]);

  const loadTagsFromCollection = async () => {
    try {
      const { data, error } = await supabase
        .from('tags')
        .select('name')
        .eq('active', true)
        .order('order', { ascending: true });

      if (error) throw error;

      const tags = data
        ?.map((tag: any) => tag.name?.toLowerCase() || "")
        .filter(Boolean) || [];

      setTagsFromCollection(tags);
    } catch (error) {
      console.error("Error loading tags:", error);
      setTagsFromCollection([]);
    }
  };

  const loadVenues = async () => {
    try {
      // Performance: Only select needed fields
      const { data, error } = await supabase
        .from('venues')
        .select('id, name, coordinates');

      if (error) throw error;

      const loadedVenues: Venue[] = (data || []).map((venue: any) => ({
        id: venue.id,
        name: venue.name ?? venue.id,
        coordinates: venue.coordinates,
      }));

      setVenues(loadedVenues);

      // Build venue cache for faster lookups
      const cache = new Map<string, string>();
      loadedVenues.forEach(v => cache.set(v.id, v.name));
      setVenueCache(cache);
    } catch (error) {
      console.error("Error loading venues:", error);
      toast.error("Failed to load venues");
    }
  };

  const loadEvents = async () => {
    if (!user) return;
    setLoading(true);

    try {
      let query = supabase
        .from('events')
        .select('*')
        .order('start_time', { ascending: false });

      // Role-based filtering
      if (user.role === "venueAdmin" || user.role === "subAdmin") {
        if (!user.venueId) {
          toast.error("No venue assigned to your account");
          setEvents([]);
          setLoading(false);
          return;
        }
        query = query.eq('venue_id', user.venueId);
      } else if (user.role !== "siteAdmin") {
        setEvents([]);
        setLoading(false);
        return;
      }

      const { data, error } = await query;

      if (error) throw error;

      const list: Event[] = (data || []).map((d: any) => ({
        ...d,
        // Keep both naming conventions for compatibility
        venueId: d.venue_id,
        startTime: d.start_time,
        endTime: d.end_time,
        isFeatured: d.is_featured,
        featuredPriority: d.featured_priority,
        imageUrl: d.image_url,
        maxTickets: d.max_tickets,
        ticketsSold: d.tickets_sold,
        organizerId: d.organizer_id,
        createdAt: d.created_at,
        updatedAt: d.updated_at,
      }));

      // Sort featured events to top
      list.sort((a, b) => {
        const featuredSort = Number(!!b.is_featured) - Number(!!a.is_featured);
        if (featuredSort !== 0) return featuredSort;

        // Then by featured priority if both featured
        if (a.is_featured && b.is_featured) {
          const aPriority = a.featured_priority ?? 999;
          const bPriority = b.featured_priority ?? 999;
          if (aPriority !== bPriority) return aPriority - bPriority;
        }

        const aDate = toDate(a.start_time) ?? new Date(0);
        const bDate = toDate(b.start_time) ?? new Date(0);
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
    const tagSet = new Set<string>(tagsFromCollection);
    events.forEach((event) => {
      const tags = event.tags ?? [];
      if (tags.length) {
        tagSet.add(normaliseTag(tags[0]));
      }
    });
    return Array.from(tagSet).filter(Boolean);
  }, [events, tagsFromCollection]);

  // Performance: Debounced filtering and sorting
  const filtered = useMemo(() => {
    const s = search.trim().toLowerCase();

    let result = events.filter((event) => {
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

    // Apply sorting
    result.sort((a, b) => {
      switch (sortBy) {
        case "date-asc": {
          const aDate = toDate(a.start_time) ?? new Date(0);
          const bDate = toDate(b.start_time) ?? new Date(0);
          return aDate.getTime() - bDate.getTime();
        }
        case "date-desc": {
          const aDate = toDate(a.start_time) ?? new Date(0);
          const bDate = toDate(b.start_time) ?? new Date(0);
          return bDate.getTime() - aDate.getTime();
        }
        case "name-asc":
          return (a.name || "").localeCompare(b.name || "");
        case "name-desc":
          return (b.name || "").localeCompare(a.name || "");
        case "price-asc":
          return (a.price || 0) - (b.price || 0);
        case "price-desc":
          return (b.price || 0) - (a.price || 0);
        case "tickets-asc":
          return (a.tickets_sold || 0) - (b.tickets_sold || 0);
        case "tickets-desc":
          return (b.tickets_sold || 0) - (a.tickets_sold || 0);
        case "featured":
          return Number(!!b.is_featured) - Number(!!a.is_featured);
        default:
          return 0;
      }
    });

    return result;
  }, [events, search, statusFilter, tagFilter, sortBy]);

  const onToggleFeatured = async (ev: Event) => {
    if (!user || user.role !== "siteAdmin") {
      toast.error("Only site administrators can manage featured events");
      return;
    }

    try {
      const { error } = await supabase
        .from('events')
        .update({
          is_featured: !ev.is_featured,
          updated_at: new Date().toISOString(),
        })
        .eq('id', ev.id);

      if (error) throw error;

      setEvents((prev) =>
        prev.map((event) =>
          event.id === ev.id ? { ...event, is_featured: !event.is_featured } : event
        )
      );
      toast.success(`Event ${!ev.is_featured ? "featured" : "unfeatured"}`);
    } catch (error: any) {
      toast.error(error.message || "Failed to toggle feature");
    }
  };

  const onSetTopFeatured = async (ev: Event) => {
    if (!user || user.role !== "siteAdmin") {
      toast.error("Only site administrators can manage featured events");
      return;
    }

    try {
      const { error } = await supabase
        .from('events')
        .update({
          is_featured: true,
          featured_priority: 0,
          updated_at: new Date().toISOString(),
        })
        .eq('id', ev.id);

      if (error) throw error;

      setEvents((prev) =>
        prev.map((event) =>
          event.id === ev.id
            ? { ...event, is_featured: true, featured_priority: 0 }
            : event
        )
      );

      toast.success(`"${ev.name}" is now the top featured event`);
    } catch (error: any) {
      toast.error(error.message || "Failed to set top featured event");
    }
  };

  const onDelete = async (ev: Event) => {
    try {
      // Delete associated tickets first
      const { error: ticketsError } = await supabase
        .from('tickets')
        .delete()
        .eq('event_id', ev.id);

      if (ticketsError) throw ticketsError;

      // Delete image from storage if exists
      if (ev.image_url) {
        try {
          // Extract path from URL
          const urlParts = ev.image_url.split('/');
          const bucket = 'event-images';
          const path = urlParts.slice(urlParts.indexOf(bucket) + 1).join('/');

          const { error: storageError } = await supabase.storage
            .from(bucket)
            .remove([path]);

          if (storageError) console.warn("Unable to delete image", storageError);
        } catch (storageError) {
          console.warn("Unable to delete existing image", storageError);
        }
      }

      // Delete the event
      const { error } = await supabase
        .from('events')
        .delete()
        .eq('id', ev.id);

      if (error) throw error;

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
        const isSoldOut = (ev.tickets_sold ?? 0) >= (ev.max_tickets ?? 0);
        if (isSoldOut) {
          return { status: "soldOut", label: "Sold Out", variant: "destructive" as const };
        }
        return { status: "active", label: "Active", variant: "default" as const };
      }
    }
  };

  const getTicketProgress = (ev: Event) => {
    const sold = ev.tickets_sold || 0;
    const max = ev.max_tickets || 1;
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
    sortBy,
    setSortBy,
    availableTags,
    filtered,
    onToggleFeatured,
    onSetTopFeatured,
    onDelete,
    getEventStatus,
    getTicketProgress,
    loadEvents,
    setEvents,
  };
}

function deriveStatus(ev: Event): EventStatus {
  const now = new Date();
  const start = toDate(ev.start_time);
  const end = toDate(ev.end_time);

  if (!start) {
    return "draft";
  }

  if (end && end < now) {
    return "completed";
  }

  if (start > now) {
    return "scheduled";
  }

  if ((ev.tickets_sold ?? 0) >= (ev.max_tickets ?? 0)) {
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
    venueId: existing?.venue_id ?? (user.role === "siteAdmin" ? "" : user.venueId || ""),
    startDateTime: timestampToInputValue(existing?.start_time ?? null),
    endDateTime: timestampToInputValue(existing?.end_time ?? null),
    price: existing?.price ?? 0,
    maxTickets: existing?.max_tickets ?? 0,
    isFeatured: user.role === "siteAdmin" ? !!existing?.is_featured : false,
    status: (existing?.status as EventStatus) || deriveStatus(existing || ({} as Event)),
    tag: normaliseTag(existing?.tags?.[0]) || "",
  });
  const [file, setFile] = useState<File | null>(null);
  const [progress, setProgress] = useState(0);
  const [saving, setSaving] = useState(false);

  async function uploadImageIfAny(eventId: string) {
    if (!file) return existing?.image_url ?? null;

    const allowed = ["image/jpeg", "image/jpg", "image/png", "image/gif"];
    if (!allowed.includes(file.type)) throw new Error("Invalid file type");
    if (file.size > 5 * 1024 * 1024) throw new Error("File too large (max 5MB)");

    const fileName = `${Date.now()}_${file.name}`;
    const storagePath = `${eventId}/${fileName}`;

    // Upload to Supabase Storage
    const { data, error } = await supabase.storage
      .from('event-images')
      .upload(storagePath, file, {
        cacheControl: '3600',
        upsert: false,
      });

    if (error) throw error;

    // Get public URL
    const { data: { publicUrl } } = supabase.storage
      .from('event-images')
      .getPublicUrl(storagePath);

    // Delete old image if exists and is different
    if (existing?.image_url && existing.image_url !== publicUrl) {
      try {
        const urlParts = existing.image_url.split('/');
        const oldPath = urlParts.slice(urlParts.indexOf(eventId)).join('/');
        await supabase.storage.from('event-images').remove([oldPath]);
      } catch {
        /* ignore */
      }
    }

    return publicUrl;
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

        // Performance: Use cached venue name or fetch
        const { data: venueData } = await supabase
          .from('venues')
          .select('name')
          .eq('id', user.venueId)
          .single();

        selectedVenueName = venueData?.name || "Unknown Venue";
      }

      const start = new Date(form.startDateTime).toISOString();
      const end = form.endDateTime ? new Date(form.endDateTime).toISOString() : null;

      if (end && new Date(end) <= new Date(start)) {
        throw new Error("End time must be after start time");
      }

      const url = await uploadImageIfAny(isEdit ? existing!.id : form.id);
      const tags = form.tag ? [normaliseTag(form.tag)] : [];

      // Get coordinates from venue (cached)
      let coordinates: { latitude: number; longitude: number } | null = null;
      const { data: venueData } = await supabase
        .from('venues')
        .select('coordinates')
        .eq('id', selectedVenueId)
        .single();

      if (venueData?.coordinates) {
        coordinates = venueData.coordinates;
      }

      if (isEdit) {
        const updatePayload: any = {
          name: form.name,
          description: form.description || null,
          venue: selectedVenueName,
          venue_id: selectedVenueId,
          start_time: start,
          end_time: end,
          price: Number(form.price),
          max_tickets: Number(form.maxTickets),
          status: form.status,
          tags,
          coordinates,
          updated_at: new Date().toISOString(),
        };

        if (url) {
          updatePayload.image_url = url;
        }

        if (user.role === "siteAdmin") {
          updatePayload.is_featured = form.isFeatured;
        }

        const { error } = await supabase
          .from('events')
          .update(updatePayload)
          .eq('id', existing!.id);

        if (error) throw error;

        onSaved({
          ...(existing as Event),
          ...updatePayload,
          image_url: url ?? existing?.image_url ?? null,
        } as Event);
        toast.success("Event updated successfully");
      } else {
        if (!form.id.trim()) {
          throw new Error("Event ID is required");
        }

        const payload: any = {
          id: form.id,
          name: form.name,
          description: form.description,
          venue: selectedVenueName,
          venue_id: selectedVenueId,
          start_time: start,
          end_time: end,
          price: Number(form.price),
          max_tickets: Number(form.maxTickets),
          tickets_sold: 0,
          is_featured: user.role === "siteAdmin" ? form.isFeatured : false,
          image_url: url ?? null,
          status: form.status,
          tags,
          coordinates,
          organizer_id: user.uid,
          created_at: new Date().toISOString(),
          created_by: user.uid,
        };

        const { error } = await supabase
          .from('events')
          .insert([payload]);

        if (error) throw error;

        onSaved(payload as Event);
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
      venueId: existing?.venue_id ?? (user.role === "siteAdmin" ? "" : user.venueId || ""),
      startDateTime: timestampToInputValue(existing?.start_time ?? null),
      endDateTime: timestampToInputValue(existing?.end_time ?? null),
      price: existing?.price ?? 0,
      maxTickets: existing?.max_tickets ?? 0,
      isFeatured: user.role === "siteAdmin" ? !!existing?.is_featured : false,
      status: (existing?.status as EventStatus) || deriveStatus(existing || ({} as Event)),
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
    tagOptions: suggestedTags,
  };
}
