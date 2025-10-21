"use client";

import { useState } from "react";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import {
  Trash2,
  Plus,
  MapPin,
  Users,
  Settings,
  Mail,
  Globe,
  CalendarCheck,
  Shield,
} from "lucide-react";
import type { Venue as VenueModel } from "@/hooks/useVenuesData";

interface User {
  role: string;
  email?: string | null;
  venueId?: string | null;
}

type Venue = VenueModel;

interface VenuesHeaderProps {
  user: User;
  setShowCreateVenueDialog: (show: boolean) => void;
}

interface CreateVenueFormProps {
  showCreateVenueDialog: boolean;
  setShowCreateVenueDialog: (show: boolean) => void;
  newVenueName: string;
  setNewVenueName: (name: string) => void;
  newVenueAdminEmail: string;
  setNewVenueAdminEmail: (email: string) => void;
  newVenueAddress: string;
  setNewVenueAddress: (value: string) => void;
  newVenueCity: string;
  setNewVenueCity: (value: string) => void;
  newVenueCapacity: string;
  setNewVenueCapacity: (value: string) => void;
  newVenueContactEmail: string;
  setNewVenueContactEmail: (value: string) => void;
  newVenueWebsite: string;
  setNewVenueWebsite: (value: string) => void;
  actionLoading: boolean;
  handleCreateVenueWithAdmin: (e: React.FormEvent) => void;
  resetCreateForm: () => void;
}

interface EmptyVenuesStateProps {
  user: User;
  setShowCreateVenueDialog: (show: boolean) => void;
}

interface VenueCardProps {
  venue: Venue;
  user: User;
  actionLoading: boolean;
  handleRemoveVenue: (venueId: string) => void;
}

export function AccessDenied() {
  return (
    <div className="flex flex-col items-center justify-center min-h-[400px] text-center">
      <div className="text-6xl mb-4">🚫</div>
      <h2 className="text-2xl font-bold mb-2">Access Denied</h2>
      <p className="text-muted-foreground">
        You don't have permission to view this page.
      </p>
    </div>
  );
}

export function VenuesHeader({ user, setShowCreateVenueDialog }: VenuesHeaderProps) {
  return (
    <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
      <div>
        <h1 className="text-3xl font-bold">Venues</h1>
        <p className="text-muted-foreground mt-1">
          {user.role === "siteAdmin"
            ? "Manage venue profiles, contacts, and dashboard access."
            : "Overview of the venues you can manage."}
        </p>
      </div>

      {user.role === "siteAdmin" && (
        <Button
          onClick={() => setShowCreateVenueDialog(true)}
          className="flex items-center gap-2"
        >
          <Plus className="h-4 w-4" />
          Create Venue
        </Button>
      )}
    </div>
  );
}

export function CreateVenueForm({
  showCreateVenueDialog,
  setShowCreateVenueDialog,
  newVenueName,
  setNewVenueName,
  newVenueAdminEmail,
  setNewVenueAdminEmail,
  newVenueAddress,
  setNewVenueAddress,
  newVenueCity,
  setNewVenueCity,
  newVenueCapacity,
  setNewVenueCapacity,
  newVenueContactEmail,
  setNewVenueContactEmail,
  newVenueWebsite,
  setNewVenueWebsite,
  actionLoading,
  handleCreateVenueWithAdmin,
  resetCreateForm,
}: CreateVenueFormProps) {
  return (
    <Dialog open={showCreateVenueDialog} onOpenChange={setShowCreateVenueDialog}>
      <DialogContent className="max-w-2xl">
        <DialogHeader>
          <DialogTitle>Create New Venue</DialogTitle>
          <DialogDescription>
            Define the key contact and capacity details for this venue. Admin access will be granted automatically.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleCreateVenueWithAdmin} className="space-y-6">
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-2">
              <Label htmlFor="venue-name">Venue Name</Label>
              <Input
                id="venue-name"
                type="text"
                placeholder="Enter venue name"
                value={newVenueName}
                onChange={(e) => setNewVenueName(e.target.value)}
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="admin-email">Primary Admin Email</Label>
              <Input
                id="admin-email"
                type="email"
                placeholder="admin@venue.com"
                value={newVenueAdminEmail}
                onChange={(e) => setNewVenueAdminEmail(e.target.value)}
                required
              />
              <p className="text-xs text-muted-foreground">
                We'll invite this user as the venue admin after creation.
              </p>
            </div>
          </div>

          <div className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-2">
              <Label htmlFor="venue-address">Address (optional)</Label>
              <Input
                id="venue-address"
                type="text"
                placeholder="123 Temple Street"
                value={newVenueAddress}
                onChange={(e) => setNewVenueAddress(e.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="venue-city">City</Label>
              <Input
                id="venue-city"
                type="text"
                placeholder="London"
                value={newVenueCity}
                onChange={(e) => setNewVenueCity(e.target.value)}
              />
            </div>
          </div>

          <div className="grid gap-4 sm:grid-cols-3">
            <div className="space-y-2 sm:col-span-1">
              <Label htmlFor="venue-capacity">Capacity</Label>
              <Input
                id="venue-capacity"
                type="number"
                min="0"
                placeholder="500"
                value={newVenueCapacity}
                onChange={(e) => setNewVenueCapacity(e.target.value)}
              />
              <p className="text-xs text-muted-foreground">Used for ticket allocations.</p>
            </div>
            <div className="space-y-2 sm:col-span-1">
              <Label htmlFor="contact-email">Contact Email</Label>
              <Input
                id="contact-email"
                type="email"
                placeholder="hello@venue.com"
                value={newVenueContactEmail}
                onChange={(e) => setNewVenueContactEmail(e.target.value)}
              />
            </div>
            <div className="space-y-2 sm:col-span-1">
              <Label htmlFor="venue-website">Website</Label>
              <Input
                id="venue-website"
                type="url"
                placeholder="https://venue.com"
                value={newVenueWebsite}
                onChange={(e) => setNewVenueWebsite(e.target.value)}
              />
            </div>
          </div>

          <div className="flex justify-end gap-2">
            <Button
              type="button"
              variant="outline"
              onClick={() => {
                setShowCreateVenueDialog(false);
                resetCreateForm();
              }}
            >
              Cancel
            </Button>
            <Button type="submit" disabled={actionLoading}>
              {actionLoading ? "Creating..." : "Create Venue"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}

export function EmptyVenuesState({ user, setShowCreateVenueDialog }: EmptyVenuesStateProps) {
  return (
    <Card className="text-center py-12 border-dashed">
      <CardContent className="space-y-4">
        <div className="text-6xl">🏢</div>
        <h3 className="text-xl font-semibold">No venues yet</h3>
        <p className="text-muted-foreground">
          {user.role === "siteAdmin"
            ? "Create your first venue to assign admins, scanners, and build events."
            : "You'll see your venue once an admin adds you to their team."}
        </p>
        {user.role === "siteAdmin" && (
          <Button onClick={() => setShowCreateVenueDialog(true)}>
            <Plus className="h-4 w-4 mr-2" />
            Create First Venue
          </Button>
        )}
      </CardContent>
    </Card>
  );
}

export function VenueGridCard({ venue, user, actionLoading, handleRemoveVenue }: VenueCardProps) {
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);

  const location = [venue.address, venue.city].filter(Boolean).join(", ");
  const adminCount = venue.admins?.length ?? 0;
  const subAdminCount = venue.subAdmins?.length ?? 0;
  const eventCount = typeof venue.eventCount === "number" ? venue.eventCount : null;
  const capacity = venue.capacity ? venue.capacity.toLocaleString() : null;

  return (
    <>
      <Card className="h-full flex flex-col justify-between transition-all duration-200 hover:shadow-lg">
        <CardHeader className="pb-4">
          <div className="flex items-start justify-between gap-3">
            <div className="space-y-1 min-w-0">
              <CardTitle className="text-lg truncate">{venue.name}</CardTitle>
              <CardDescription className="flex items-center gap-2 text-muted-foreground text-sm">
                <MapPin className="h-4 w-4 text-primary" />
                <span className="truncate">{location || "Location TBC"}</span>
              </CardDescription>
            </div>
            <div className="flex items-center gap-2">
              <Badge variant={venue.active === false ? "secondary" : "default"} className="text-xs">
                {venue.active === false ? "Inactive" : "Active"}
              </Badge>
              {user.role === "siteAdmin" && (
                <Button
                  variant="ghost"
                  size="icon"
                  className="text-muted-foreground hover:text-destructive"
                  onClick={() => setShowDeleteDialog(true)}
                >
                  <Trash2 className="h-4 w-4" />
                </Button>
              )}
            </div>
          </div>
        </CardHeader>
        <CardContent className="space-y-4 pt-0">
          <div className="space-y-3 text-sm">
            {venue.contactEmail && (
              <div className="flex items-center gap-3 text-muted-foreground">
                <Mail className="h-4 w-4 text-primary" />
                <span className="truncate">{venue.contactEmail}</span>
              </div>
            )}
            {venue.website && (
              <div className="flex items-center gap-3 text-muted-foreground">
                <Globe className="h-4 w-4 text-primary" />
                <a
                  href={venue.website}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="truncate hover:underline"
                >
                  {venue.website}
                </a>
              </div>
            )}
          </div>

          <Separator />

          <div className="grid grid-cols-2 gap-3 text-sm">
            <div className="rounded-lg border bg-muted/40 p-3">
              <p className="text-xs text-muted-foreground">Admins</p>
              <div className="flex items-center gap-2 font-medium">
                <Shield className="h-4 w-4 text-primary" />
                {adminCount}
              </div>
            </div>
            <div className="rounded-lg border bg-muted/40 p-3">
              <p className="text-xs text-muted-foreground">Sub-admins</p>
              <div className="flex items-center gap-2 font-medium">
                <Shield className="h-4 w-4 text-muted-foreground" />
                {subAdminCount}
              </div>
            </div>
            <div className="rounded-lg border bg-muted/40 p-3">
              <p className="text-xs text-muted-foreground">Capacity</p>
              <div className="flex items-center gap-2 font-medium">
                <Users className="h-4 w-4 text-primary" />
                {capacity ?? "—"}
              </div>
            </div>
            <div className="rounded-lg border bg-muted/40 p-3">
              <p className="text-xs text-muted-foreground">Events hosted</p>
              <div className="flex items-center gap-2 font-medium">
                <CalendarCheck className="h-4 w-4 text-primary" />
                {eventCount !== null ? eventCount : "—"}
              </div>
            </div>
          </div>
        </CardContent>
        <CardFooter className="pt-0">
          <div className="flex w-full gap-2">
            {user.role === "siteAdmin" && (
              <Button asChild variant="outline" className="flex-1">
                <Link href="/admin-management" className="flex items-center justify-center gap-2">
                  <Users className="h-4 w-4" />
                  Manage Admins
                </Link>
              </Button>
            )}
            <Button asChild variant="outline" className="flex-1">
              <Link href="/events" className="flex items-center justify-center gap-2">
                <CalendarCheck className="h-4 w-4" />
                View Events
              </Link>
            </Button>
          </div>
        </CardFooter>
      </Card>

      <Dialog open={showDeleteDialog} onOpenChange={setShowDeleteDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Venue</DialogTitle>
            <DialogDescription>
              Removing a venue will also revoke any venue admin or scanner access tied to it.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <p>
              Are you sure you want to delete "{venue.name}"? This action cannot be undone.
            </p>
            <div className="flex justify-end gap-2">
              <Button variant="outline" onClick={() => setShowDeleteDialog(false)}>
                Cancel
              </Button>
              <Button
                variant="destructive"
                onClick={() => {
                  handleRemoveVenue(venue.id);
                  setShowDeleteDialog(false);
                }}
                disabled={actionLoading}
              >
                {actionLoading ? "Deleting..." : "Delete Venue"}
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </>
  );
}

export function VenueCard({ venue, user, actionLoading, handleRemoveVenue }: VenueCardProps) {
  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle className="flex items-center gap-2">
            <MapPin className="h-5 w-5" />
            {venue.name}
          </CardTitle>
          {user.role === "siteAdmin" && (
            <Button
              variant="destructive"
              size="sm"
              onClick={() => handleRemoveVenue(venue.id)}
              disabled={actionLoading}
            >
              <Trash2 className="h-4 w-4 mr-2" />
              Remove
            </Button>
          )}
        </div>
      </CardHeader>
      <CardContent className="space-y-2">
        <div className="flex gap-2">
          {user.role === "siteAdmin" && (
            <Button asChild variant="link" className="px-0">
              <Link href="/admin-management" className="inline-flex items-center gap-2">
                <Users className="h-4 w-4" />
                Manage Admins
              </Link>
            </Button>
          )}
          <Button asChild variant="link" className="px-0">
            <Link href="/events" className="inline-flex items-center gap-2">
              <CalendarCheck className="h-4 w-4" />
              View Events
            </Link>
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}
