"use client";

import { useMemo, useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { format } from "date-fns";
import { Plus, Pencil, Trash2 } from "lucide-react";

import { useEvents } from "@/hooks/use-events";
import { useTags } from "@/hooks/use-tags";
import {
  createEvent,
  updateEvent,
  deleteEvent
} from "@/lib/firestore/events";
import type { EventRecord } from "@/lib/types";
import {
  eventFormSchema,
  type EventFormValues
} from "@/lib/validators";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogDescription } from "@/components/ui/dialog";
import { Form, FormControl, FormDescription, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectGroup, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Switch } from "@/components/ui/switch";
import { Separator } from "@/components/ui/separator";

function toDateTimeLocal(date: Date | null | undefined) {
  if (!date) return "";
  const tzOffset = date.getTimezoneOffset() * 60000;
  const localISOTime = new Date(date.getTime() - tzOffset).toISOString().slice(0, 16);
  return localISOTime;
}

export default function EventsPage() {
  const { events, loading } = useEvents();
  const { tags } = useTags();
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editing, setEditing] = useState<EventRecord | null>(null);
  const [feedback, setFeedback] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const form = useForm<EventFormValues>({
    resolver: zodResolver(eventFormSchema),
    defaultValues: {
      name: "",
      venueName: "",
      venueId: null,
      price: 0,
      maxTickets: 0,
      startTime: null,
      endTime: null,
      imageUrl: null,
      description: null,
      status: "active",
      category: null,
      isFeatured: false,
      tagId: null,
      tagName: null
    }
  });

  const resetForm = (event?: EventRecord | null) => {
    if (event) {
      form.reset({
        name: event.name,
        venueName: event.venueName,
        venueId: event.venueId ?? null,
        price: event.price,
        maxTickets: event.maxTickets,
        startTime: event.startTime ? toDateTimeLocal(event.startTime) : null,
        endTime: event.endTime ? toDateTimeLocal(event.endTime) : null,
        imageUrl: event.imageUrl ?? null,
        description: event.description ?? null,
        status: event.status ?? "active",
        category: event.category ?? null,
        isFeatured: event.isFeatured ?? false,
        tagId: event.tagId ?? null,
        tagName: event.tagName ?? null
      });
    } else {
      form.reset({
        name: "",
        venueName: "",
        venueId: null,
        price: 0,
        maxTickets: 0,
        startTime: null,
        endTime: null,
        imageUrl: null,
        description: null,
        status: "active",
        category: null,
        isFeatured: false,
        tagId: null,
        tagName: null
      });
    }
  };

  const handleOpenCreate = () => {
    setEditing(null);
    resetForm(null);
    setDialogOpen(true);
    setFeedback(null);
  };

  const handleEdit = (event: EventRecord) => {
    setEditing(event);
    resetForm(event);
    setDialogOpen(true);
    setFeedback(null);
  };

  const onSubmit = async (values: EventFormValues) => {
    try {
      setIsSubmitting(true);
      const payload = {
        ...values,
        startTime: values.startTime ? new Date(values.startTime) : null,
        endTime: values.endTime ? new Date(values.endTime) : null
      };

      if (editing) {
        await updateEvent(editing.id, payload, editing);
        setFeedback("Event updated successfully.");
      } else {
        await createEvent(payload);
        setFeedback("Event created successfully.");
      }

      setDialogOpen(false);
      setEditing(null);
    } catch (error) {
      console.error(error);
      setFeedback((error as Error).message ?? "Failed to save event");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDelete = async (event: EventRecord) => {
    const confirm = window.confirm(`Delete event "${event.name}"? This cannot be undone.`);
    if (!confirm) return;

    try {
      await deleteEvent(event.id);
      setFeedback("Event deleted.");
    } catch (error) {
      console.error(error);
      setFeedback((error as Error).message ?? "Failed to delete event");
    }
  };

  const sortedEvents = useMemo(() => {
    return [...events].sort((a, b) => {
      const aTime = a.startTime?.getTime() ?? 0;
      const bTime = b.startTime?.getTime() ?? 0;
      return aTime - bTime;
    });
  }, [events]);

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h2 className="text-2xl font-semibold tracking-tight">Events</h2>
          <p className="text-sm text-muted-foreground">
            Event metadata now uses single-tag assignments and supports end times.
          </p>
        </div>
        <Button onClick={handleOpenCreate}>
          <Plus className="mr-2 h-4 w-4" /> New event
        </Button>
      </div>

      {feedback ? (
        <Card className="border-primary/40 bg-primary/10 text-sm text-primary">
          <CardContent className="py-3">{feedback}</CardContent>
        </Card>
      ) : null}

      <Card className="bg-card/40">
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-4">
          <CardTitle className="text-base">Upcoming schedule</CardTitle>
          <span className="text-xs text-muted-foreground">{sortedEvents.length} events</span>
        </CardHeader>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="w-64">Name</TableHead>
                <TableHead className="w-48">Start</TableHead>
                <TableHead className="w-48">End</TableHead>
                <TableHead>Tag</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="text-right">Tickets</TableHead>
                <TableHead className="w-32 text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {sortedEvents.map((event) => (
                <TableRow key={event.id}>
                  <TableCell>
                    <div>
                      <p className="font-medium">{event.name}</p>
                      <p className="text-xs text-muted-foreground">{event.venueName}</p>
                    </div>
                  </TableCell>
                  <TableCell>
                    {event.startTime ? format(event.startTime, "MMM d, yyyy p") : <span className="text-muted-foreground">TBA</span>}
                  </TableCell>
                  <TableCell>
                    {event.endTime ? format(event.endTime, "MMM d, yyyy p") : <span className="text-muted-foreground">Not set</span>}
                  </TableCell>
                  <TableCell>
                    {event.tagName ? <Badge variant="secondary">{event.tagName}</Badge> : <span className="text-muted-foreground">No tag</span>}
                  </TableCell>
                  <TableCell className="capitalize text-muted-foreground">{event.status ?? "active"}</TableCell>
                  <TableCell className="text-right text-sm">
                    {event.ticketsSold} / {event.maxTickets}
                  </TableCell>
                  <TableCell className="text-right">
                    <div className="flex justify-end gap-2">
                      <Button variant="ghost" size="icon" onClick={() => handleEdit(event)}>
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <Button variant="ghost" size="icon" onClick={() => handleDelete(event)}>
                        <Trash2 className="h-4 w-4 text-destructive" />
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
              {!loading && sortedEvents.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={7} className="py-10 text-center text-sm text-muted-foreground">
                    No events found. Create your first event to populate the schedule.
                  </TableCell>
                </TableRow>
              ) : null}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      <Dialog
        open={dialogOpen}
        onOpenChange={(open) => {
          setDialogOpen(open);
          if (!open) {
            setEditing(null);
          }
        }}
      >
        <DialogContent className="max-w-3xl">
          <DialogHeader>
            <DialogTitle>{editing ? "Edit event" : "Create event"}</DialogTitle>
            <DialogDescription>
              Configure event timing, capacity, and assign a single tag used throughout the Burner app.
            </DialogDescription>
          </DialogHeader>
          <Form {...form}>
            <form className="space-y-6" onSubmit={form.handleSubmit(onSubmit)}>
              <div className="grid gap-4 md:grid-cols-2">
                <FormField
                  control={form.control}
                  name="name"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Event name</FormLabel>
                      <FormControl>
                        <Input placeholder="Sunrise Session" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="venueName"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Venue</FormLabel>
                      <FormControl>
                        <Input placeholder="The Burner Warehouse" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="startTime"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Start time</FormLabel>
                      <FormControl>
                        <Input
                          type="datetime-local"
                          value={field.value ?? ''}
                          onChange={(event) => field.onChange(event.target.value)}
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="endTime"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>End time</FormLabel>
                      <FormControl>
                        <Input
                          type="datetime-local"
                          value={field.value ?? ''}
                          onChange={(event) => field.onChange(event.target.value)}
                        />
                      </FormControl>
                      <FormDescription>Guests lose access to Burner Mode after this time.</FormDescription>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="price"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Ticket price</FormLabel>
                      <FormControl>
                        <Input type="number" step="0.01" min="0" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="maxTickets"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Capacity</FormLabel>
                      <FormControl>
                        <Input type="number" min="0" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="tagId"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Tag</FormLabel>
                      <Select
                        value={field.value ?? undefined}
                        onValueChange={(value) => {
                          const tag = tags.find((item) => item.id === value);
                          field.onChange(value);
                          form.setValue("tagName", tag?.name ?? null);
                        }}
                      >
                        <FormControl>
                          <SelectTrigger>
                            <SelectValue placeholder="Select one tag" />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          <SelectGroup>
                            <SelectItem value="">No tag</SelectItem>
                            {tags.map((tag) => (
                              <SelectItem key={tag.id} value={tag.id}>
                                {tag.name}
                              </SelectItem>
                            ))}
                          </SelectGroup>
                        </SelectContent>
                      </Select>
                      <FormDescription>Each event can publish one tag for filtering in Burner apps.</FormDescription>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="status"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Status</FormLabel>
                      <Select value={field.value ?? "active"} onValueChange={field.onChange}>
                        <FormControl>
                          <SelectTrigger>
                            <SelectValue />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          <SelectItem value="active">Active</SelectItem>
                          <SelectItem value="soldOut">Sold out</SelectItem>
                          <SelectItem value="cancelled">Cancelled</SelectItem>
                          <SelectItem value="draft">Draft</SelectItem>
                        </SelectContent>
                      </Select>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="category"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Category</FormLabel>
                      <FormControl>
                        <Input placeholder="Optional category" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>

              <FormField
                control={form.control}
                name="imageUrl"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Header image URL</FormLabel>
                    <FormControl>
                      <Input placeholder="https://..." {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="description"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Description</FormLabel>
                    <FormControl>
                      <Textarea rows={4} placeholder="Tell Burners why this matters" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <div className="flex items-center justify-between rounded-lg border border-border/60 bg-muted/10 p-4">
                <div className="space-y-1">
                  <FormLabel className="text-base">Featured event</FormLabel>
                  <p className="text-xs text-muted-foreground">
                    Feature this event on the dashboard home carousel.
                  </p>
                </div>
                <FormField
                  control={form.control}
                  name="isFeatured"
                  render={({ field }) => (
                    <FormItem>
                      <FormControl>
                        <Switch checked={field.value} onCheckedChange={field.onChange} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>

              <Separator className="bg-border/60" />

              <DialogFooter className="pt-2">
                <Button type="submit" disabled={isSubmitting}>
                  {isSubmitting ? "Saving..." : "Save event"}
                </Button>
              </DialogFooter>
            </form>
          </Form>
        </DialogContent>
      </Dialog>
    </div>
  );
}
