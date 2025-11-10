import { useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { Plus, Building2, MapPin, Users, Mail, Globe, Trash2, Edit, UserPlus, X } from "lucide-react";
import type { Venue } from "@/hooks/useVenuesData";

export function AccessDenied() {
  return (
    <Card className="max-w-md mx-auto mt-10">
      <CardHeader>
        <CardTitle className="text-center">Access Denied</CardTitle>
      </CardHeader>
      <CardContent>
        <p className="text-center text-muted-foreground">
          You do not have permission to view this page.
        </p>
      </CardContent>
    </Card>
  );
}

export function VenuesHeader({
  user,
  setShowCreateVenueDialog,
}: {
  user: any;
  setShowCreateVenueDialog: (show: boolean) => void;
}) {
  return (
    <div className="flex items-center justify-between">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">
          {user?.role === "siteAdmin" ? "Venues" : "My Venue"}
        </h1>
      </div>
      {user?.role === "siteAdmin" && (
        <Button
          onClick={() => setShowCreateVenueDialog(true)}
          size="lg"
          className="shadow-md"
        >
          <Plus className="mr-2 h-4 w-4" />
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
  newVenueLatitude,
  setNewVenueLatitude,
  newVenueLongitude,
  setNewVenueLongitude,
  newVenueCapacity,
  setNewVenueCapacity,
  newVenueContactEmail,
  setNewVenueContactEmail,
  newVenueWebsite,
  setNewVenueWebsite,
  actionLoading,
  handleCreateVenueWithAdmin,
  resetCreateForm,
}: {
  showCreateVenueDialog: boolean;
  setShowCreateVenueDialog: (show: boolean) => void;
  newVenueName: string;
  setNewVenueName: (name: string) => void;
  newVenueAdminEmail: string;
  setNewVenueAdminEmail: (email: string) => void;
  newVenueAddress: string;
  setNewVenueAddress: (address: string) => void;
  newVenueCity: string;
  setNewVenueCity: (city: string) => void;
  newVenueLatitude: string;
  setNewVenueLatitude: (latitude: string) => void;
  newVenueLongitude: string;
  setNewVenueLongitude: (longitude: string) => void;
  newVenueCapacity: string;
  setNewVenueCapacity: (capacity: string) => void;
  newVenueContactEmail: string;
  setNewVenueContactEmail: (email: string) => void;
  newVenueWebsite: string;
  setNewVenueWebsite: (website: string) => void;
  actionLoading: boolean;
  handleCreateVenueWithAdmin: (e: React.FormEvent) => Promise<void>;
  resetCreateForm: () => void;
}) {
  return (
    <Dialog 
      open={showCreateVenueDialog} 
      onOpenChange={(open) => {
        setShowCreateVenueDialog(open);
        if (!open) resetCreateForm();
      }}
    >
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Create New Venue</DialogTitle>
          <DialogDescription>
            Enter the venue details and assign an initial admin. All fields marked with * are required.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleCreateVenueWithAdmin}>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="venue-name">Venue Name *</Label>
              <Input
                id="venue-name"
                placeholder="The Venue Name"
                value={newVenueName}
                onChange={(e) => setNewVenueName(e.target.value)}
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="admin-email">Admin Email *</Label>
              <Input
                id="admin-email"
                type="email"
                placeholder="admin@example.com"
                value={newVenueAdminEmail}
                onChange={(e) => setNewVenueAdminEmail(e.target.value)}
                required
              />
              <p className="text-xs text-muted-foreground">
                This person will be set as the venue administrator
              </p>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="address">Address (Optional)</Label>
                <Input
                  id="address"
                  placeholder="123 Main Street"
                  value={newVenueAddress}
                  onChange={(e) => setNewVenueAddress(e.target.value)}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="city">City (Optional)</Label>
                <Input
                  id="city"
                  placeholder="London"
                  value={newVenueCity}
                  onChange={(e) => setNewVenueCity(e.target.value)}
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="latitude">Latitude *</Label>
                <Input
                  id="latitude"
                  type="number"
                  step="any"
                  placeholder="51.5074"
                  value={newVenueLatitude}
                  onChange={(e) => setNewVenueLatitude(e.target.value)}
                  required
                />
                <p className="text-xs text-muted-foreground">
                  Required for map display in the app
                </p>
              </div>

              <div className="space-y-2">
                <Label htmlFor="longitude">Longitude *</Label>
                <Input
                  id="longitude"
                  type="number"
                  step="any"
                  placeholder="-0.1278"
                  value={newVenueLongitude}
                  onChange={(e) => setNewVenueLongitude(e.target.value)}
                  required
                />
                <p className="text-xs text-muted-foreground">
                  Required for map display in the app
                </p>
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="capacity">Capacity</Label>
              <Input
                id="capacity"
                type="number"
                placeholder="500"
                value={newVenueCapacity}
                onChange={(e) => setNewVenueCapacity(e.target.value)}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="contact-email">Contact Email</Label>
              <Input
                id="contact-email"
                type="email"
                placeholder="info@venue.com"
                value={newVenueContactEmail}
                onChange={(e) => setNewVenueContactEmail(e.target.value)}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="website">Website</Label>
              <Input
                id="website"
                type="url"
                placeholder="https://venue.com"
                value={newVenueWebsite}
                onChange={(e) => setNewVenueWebsite(e.target.value)}
              />
            </div>
          </div>

          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => {
                setShowCreateVenueDialog(false);
                resetCreateForm();
              }}
              disabled={actionLoading}
            >
              Cancel
            </Button>
            <Button type="submit" disabled={actionLoading}>
              {actionLoading ? "Creating..." : "Create Venue"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

export function EmptyVenuesState({
  user,
  setShowCreateVenueDialog,
}: {
  user: any;
  setShowCreateVenueDialog: (show: boolean) => void;
}) {
  return (
    <Card className="border-dashed">
      <CardContent className="flex flex-col items-center justify-center py-12">
        <Building2 className="h-12 w-12 text-muted-foreground mb-4" />
        <h3 className="text-lg font-semibold mb-2">No venues found</h3>
        <p className="text-muted-foreground text-center mb-6 max-w-sm">
          {user?.role === "siteAdmin"
            ? "Get started by creating your first venue. You'll be able to assign admins and manage events for each venue."
            : "No venue has been assigned to your account. Please contact a site administrator."}
        </p>
        {user?.role === "siteAdmin" && (
          <Button onClick={() => setShowCreateVenueDialog(true)}>
            <Plus className="mr-2 h-4 w-4" />
            Create First Venue
          </Button>
        )}
      </CardContent>
    </Card>
  );
}

// Site Admin View - Grid of venue cards with edit capabilities
export function VenueGridCard({
  venue,
  user,
  actionLoading,
  handleRemoveVenue,
  handleUpdateVenue,
  handleAddAdmin,
  handleRemoveAdmin,
}: {
  venue: Venue;
  user: any;
  actionLoading: boolean;
  handleRemoveVenue: (venueId: string) => Promise<void>;
  handleUpdateVenue: (venueId: string, updates: Partial<Venue>) => Promise<void>;
  handleAddAdmin: (venueId: string, email: string, role: 'venueAdmin' | 'subAdmin') => Promise<void>;
  handleRemoveAdmin: (venueId: string, email: string, isVenueAdmin: boolean) => Promise<void>;
}) {
  const [showEditDialog, setShowEditDialog] = useState(false);
  const [showAdminsDialog, setShowAdminsDialog] = useState(false);
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);
  const [editForm, setEditForm] = useState({
    name: venue.name,
    address: venue.address || "",
    city: venue.city || "",
    latitude: venue.latitude?.toString() || "",
    longitude: venue.longitude?.toString() || "",
    capacity: venue.capacity?.toString() || "",
    contactEmail: venue.contactEmail || "",
    website: venue.website || "",
  });
  const [newAdminEmail, setNewAdminEmail] = useState("");
  const [newAdminRole, setNewAdminRole] = useState<'venueAdmin' | 'subAdmin'>('subAdmin');

  const handleEditSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    await handleUpdateVenue(venue.id, {
      name: editForm.name,
      address: editForm.address || undefined,
      city: editForm.city || undefined,
      latitude: editForm.latitude ? Number(editForm.latitude) : undefined,
      longitude: editForm.longitude ? Number(editForm.longitude) : undefined,
      capacity: editForm.capacity ? Number(editForm.capacity) : undefined,
      contactEmail: editForm.contactEmail || undefined,
      website: editForm.website || undefined,
    });
    setShowEditDialog(false);
  };

  const handleAddAdminSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    await handleAddAdmin(venue.id, newAdminEmail, newAdminRole);
    setNewAdminEmail("");
  };

  return (
    <>
      <Card className="hover:shadow-lg transition-shadow">
        <CardHeader>
          <div className="flex items-start justify-between">
            <div className="flex-1">
              <CardTitle className="flex items-center gap-2">
                <Building2 className="h-5 w-5" />
                {venue.name}
              </CardTitle>
              <CardDescription className="mt-2 space-y-1">
                {venue.address && (
                  <div className="flex items-center gap-2 text-sm">
                    <MapPin className="h-3 w-3" />
                    {venue.address}
                    {venue.city && `, ${venue.city}`}
                  </div>
                )}
                {venue.contactEmail && (
                  <div className="flex items-center gap-2 text-sm">
                    <Mail className="h-3 w-3" />
                    {venue.contactEmail}
                  </div>
                )}
                {venue.website && (
                  <div className="flex items-center gap-2 text-sm">
                    <Globe className="h-3 w-3" />
                    <a href={venue.website} target="_blank" rel="noopener noreferrer" className="hover:underline">
                      {venue.website}
                    </a>
                  </div>
                )}
              </CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-2 gap-4 text-sm">
            {venue.capacity && (
              <div>
                <span className="text-muted-foreground">Capacity:</span>
                <div className="font-medium">{venue.capacity}</div>
              </div>
            )}
            <div>
              <span className="text-muted-foreground">Events:</span>
              <div className="font-medium">{venue.eventCount || 0}</div>
            </div>
          </div>

          <div>
            <div className="flex items-center gap-2 mb-2">
              <Users className="h-4 w-4 text-muted-foreground" />
              <span className="text-sm font-medium">Administrators</span>
            </div>
            <div className="flex flex-wrap gap-2">
              {venue.admins.map((admin) => (
                <Badge key={admin} variant="default">
                  {admin}
                </Badge>
              ))}
              {venue.subAdmins.map((admin) => (
                <Badge key={admin} variant="secondary">
                  {admin}
                </Badge>
              ))}
            </div>
          </div>

          <div className="flex gap-2 pt-2">
            <Button
              variant="outline"
              size="sm"
              className="flex-1"
              onClick={() => setShowEditDialog(true)}
            >
              <Edit className="h-4 w-4 mr-2" />
              Edit Details
            </Button>
            <Button
              variant="outline"
              size="sm"
              className="flex-1"
              onClick={() => setShowAdminsDialog(true)}
            >
              <UserPlus className="h-4 w-4 mr-2" />
              Manage Admins
            </Button>
            {user?.role === "siteAdmin" && (
              <Button
                variant="destructive"
                size="sm"
                onClick={() => setShowDeleteDialog(true)}
                disabled={actionLoading}
              >
                <Trash2 className="h-4 w-4" />
              </Button>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Edit Dialog */}
      <Dialog open={showEditDialog} onOpenChange={setShowEditDialog}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>Edit Venue Details</DialogTitle>
            <DialogDescription>
              Update the venue information below
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={handleEditSubmit}>
            <div className="space-y-4 py-4">
              <div className="space-y-2">
                <Label htmlFor="edit-name">Venue Name</Label>
                <Input
                  id="edit-name"
                  value={editForm.name}
                  onChange={(e) => setEditForm({ ...editForm, name: e.target.value })}
                  required
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="edit-address">Address (Optional)</Label>
                  <Input
                    id="edit-address"
                    value={editForm.address}
                    onChange={(e) => setEditForm({ ...editForm, address: e.target.value })}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="edit-city">City (Optional)</Label>
                  <Input
                    id="edit-city"
                    value={editForm.city}
                    onChange={(e) => setEditForm({ ...editForm, city: e.target.value })}
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="edit-latitude">Latitude *</Label>
                  <Input
                    id="edit-latitude"
                    type="number"
                    step="any"
                    value={editForm.latitude}
                    onChange={(e) => setEditForm({ ...editForm, latitude: e.target.value })}
                    required
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="edit-longitude">Longitude *</Label>
                  <Input
                    id="edit-longitude"
                    type="number"
                    step="any"
                    value={editForm.longitude}
                    onChange={(e) => setEditForm({ ...editForm, longitude: e.target.value })}
                    required
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="edit-capacity">Capacity</Label>
                <Input
                  id="edit-capacity"
                  type="number"
                  value={editForm.capacity}
                  onChange={(e) => setEditForm({ ...editForm, capacity: e.target.value })}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="edit-contact">Contact Email</Label>
                <Input
                  id="edit-contact"
                  type="email"
                  value={editForm.contactEmail}
                  onChange={(e) => setEditForm({ ...editForm, contactEmail: e.target.value })}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="edit-website">Website</Label>
                <Input
                  id="edit-website"
                  type="url"
                  value={editForm.website}
                  onChange={(e) => setEditForm({ ...editForm, website: e.target.value })}
                />
              </div>
            </div>

            <DialogFooter>
              <Button type="button" variant="outline" onClick={() => setShowEditDialog(false)}>
                Cancel
              </Button>
              <Button type="submit" disabled={actionLoading}>
                {actionLoading ? "Saving..." : "Save Changes"}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* Manage Admins Dialog */}
      <Dialog open={showAdminsDialog} onOpenChange={setShowAdminsDialog}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>Manage Administrators</DialogTitle>
            <DialogDescription>
              Add or remove administrators for {venue.name}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-6 py-4">
            {/* Add Admin Form */}
            <form onSubmit={handleAddAdminSubmit} className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="new-admin-email">Add Administrator</Label>
                <div className="flex gap-2">
                  <Input
                    id="new-admin-email"
                    type="email"
                    placeholder="admin@example.com"
                    value={newAdminEmail}
                    onChange={(e) => setNewAdminEmail(e.target.value)}
                    className="flex-1"
                  />
                  <select
                    value={newAdminRole}
                    onChange={(e) => setNewAdminRole(e.target.value as 'venueAdmin' | 'subAdmin')}
                    className="px-3 py-2 border rounded-md"
                  >
                    <option value="venueAdmin">Venue Admin</option>
                    <option value="subAdmin">Sub Admin</option>
                  </select>
                  <Button type="submit" disabled={actionLoading}>
                    <Plus className="h-4 w-4 mr-2" />
                    Add
                  </Button>
                </div>
              </div>
            </form>

            {/* Current Admins List */}
            <div className="space-y-3">
              <Label>Current Administrators</Label>
              
              {venue.admins.length > 0 && (
                <div className="space-y-2">
                  <div className="text-sm font-medium text-muted-foreground">Venue Admins</div>
                  {venue.admins.map((admin) => (
                    <div key={admin} className="flex items-center justify-between p-3 border rounded-lg">
                      <div className="flex items-center gap-2">
                        <Mail className="h-4 w-4 text-muted-foreground" />
                        <span>{admin}</span>
                        <Badge variant="default">Venue Admin</Badge>
                      </div>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => handleRemoveAdmin(venue.id, admin, true)}
                        disabled={actionLoading}
                      >
                        <X className="h-4 w-4" />
                      </Button>
                    </div>
                  ))}
                </div>
              )}

              {venue.subAdmins.length > 0 && (
                <div className="space-y-2">
                  <div className="text-sm font-medium text-muted-foreground">Sub Admins</div>
                  {venue.subAdmins.map((admin) => (
                    <div key={admin} className="flex items-center justify-between p-3 border rounded-lg">
                      <div className="flex items-center gap-2">
                        <Mail className="h-4 w-4 text-muted-foreground" />
                        <span>{admin}</span>
                        <Badge variant="secondary">Sub Admin</Badge>
                      </div>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => handleRemoveAdmin(venue.id, admin, false)}
                        disabled={actionLoading}
                      >
                        <X className="h-4 w-4" />
                      </Button>
                    </div>
                  ))}
                </div>
              )}

              {venue.admins.length === 0 && venue.subAdmins.length === 0 && (
                <p className="text-sm text-muted-foreground text-center py-4">
                  No administrators assigned yet
                </p>
              )}
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setShowAdminsDialog(false)}>
              Close
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation Dialog */}
      <AlertDialog open={showDeleteDialog} onOpenChange={setShowDeleteDialog}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Are you sure?</AlertDialogTitle>
            <AlertDialogDescription>
              This will permanently delete <strong>{venue.name}</strong> and remove all associated administrators.
              This action cannot be undone.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={() => {
                handleRemoveVenue(venue.id);
                setShowDeleteDialog(false);
              }}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              Delete Venue
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}

// Venue Admin View - Detailed single venue view
export function VenueDetailCard({
  venue,
  actionLoading,
  handleUpdateVenue,
  handleAddAdmin,
  handleRemoveAdmin,
}: {
  venue: Venue;
  actionLoading: boolean;
  handleUpdateVenue: (venueId: string, updates: Partial<Venue>) => Promise<void>;
  handleAddAdmin: (venueId: string, email: string, role: 'venueAdmin' | 'subAdmin') => Promise<void>;
  handleRemoveAdmin: (venueId: string, email: string, isVenueAdmin: boolean) => Promise<void>;
}) {
  const [isEditing, setIsEditing] = useState(false);
  const [editForm, setEditForm] = useState({
    name: venue.name,
    address: venue.address || "",
    city: venue.city || "",
    latitude: venue.latitude?.toString() || "",
    longitude: venue.longitude?.toString() || "",
    capacity: venue.capacity?.toString() || "",
    contactEmail: venue.contactEmail || "",
    website: venue.website || "",
  });
  const [newAdminEmail, setNewAdminEmail] = useState("");

  const handleEditSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    await handleUpdateVenue(venue.id, {
      name: editForm.name,
      address: editForm.address || undefined,
      city: editForm.city || undefined,
      latitude: editForm.latitude ? Number(editForm.latitude) : undefined,
      longitude: editForm.longitude ? Number(editForm.longitude) : undefined,
      capacity: editForm.capacity ? Number(editForm.capacity) : undefined,
      contactEmail: editForm.contactEmail || undefined,
      website: editForm.website || undefined,
    });
    setIsEditing(false);
  };

  const handleAddSubAdmin = async (e: React.FormEvent) => {
    e.preventDefault();
    await handleAddAdmin(venue.id, newAdminEmail, 'subAdmin');
    setNewAdminEmail("");
  };

  return (
    <div className="space-y-6">
      {/* Venue Details Card */}
      <Card>
        <CardHeader>
          <div className="flex items-start justify-between">
            <div>
              <CardTitle className="text-2xl flex items-center gap-2">
                <Building2 className="h-6 w-6" />
                {venue.name}
              </CardTitle>
              <CardDescription className="mt-2">
                Manage your venue details and team members
              </CardDescription>
            </div>
            {!isEditing && (
              <Button
                variant="outline"
                onClick={() => setIsEditing(true)}
              >
                <Edit className="h-4 w-4 mr-2" />
                Edit Details
              </Button>
            )}
          </div>
        </CardHeader>
        <CardContent>
          {isEditing ? (
            <form onSubmit={handleEditSubmit} className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="venue-name">Venue Name</Label>
                <Input
                  id="venue-name"
                  value={editForm.name}
                  onChange={(e) => setEditForm({ ...editForm, name: e.target.value })}
                  required
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="address">Address (Optional)</Label>
                  <Input
                    id="address"
                    value={editForm.address}
                    onChange={(e) => setEditForm({ ...editForm, address: e.target.value })}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="city">City (Optional)</Label>
                  <Input
                    id="city"
                    value={editForm.city}
                    onChange={(e) => setEditForm({ ...editForm, city: e.target.value })}
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="latitude">Latitude *</Label>
                  <Input
                    id="latitude"
                    type="number"
                    step="any"
                    value={editForm.latitude}
                    onChange={(e) => setEditForm({ ...editForm, latitude: e.target.value })}
                    required
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="longitude">Longitude *</Label>
                  <Input
                    id="longitude"
                    type="number"
                    step="any"
                    value={editForm.longitude}
                    onChange={(e) => setEditForm({ ...editForm, longitude: e.target.value })}
                    required
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="capacity">Capacity</Label>
                <Input
                  id="capacity"
                  type="number"
                  value={editForm.capacity}
                  onChange={(e) => setEditForm({ ...editForm, capacity: e.target.value })}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="contact-email">Contact Email</Label>
                <Input
                  id="contact-email"
                  type="email"
                  value={editForm.contactEmail}
                  onChange={(e) => setEditForm({ ...editForm, contactEmail: e.target.value })}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="website">Website</Label>
                <Input
                  id="website"
                  type="url"
                  value={editForm.website}
                  onChange={(e) => setEditForm({ ...editForm, website: e.target.value })}
                />
              </div>

              <div className="flex gap-2">
                <Button type="submit" disabled={actionLoading}>
                  {actionLoading ? "Saving..." : "Save Changes"}
                </Button>
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => {
                    setIsEditing(false);
                    setEditForm({
                      name: venue.name,
                      address: venue.address || "",
                      city: venue.city || "",
                      latitude: venue.latitude?.toString() || "",
                      longitude: venue.longitude?.toString() || "",
                      capacity: venue.capacity?.toString() || "",
                      contactEmail: venue.contactEmail || "",
                      website: venue.website || "",
                    });
                  }}
                >
                  Cancel
                </Button>
              </div>
            </form>
          ) : (
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-6">
                {venue.address && (
                  <div>
                    <div className="flex items-center gap-2 text-sm text-muted-foreground mb-1">
                      <MapPin className="h-4 w-4" />
                      Address
                    </div>
                    <div className="font-medium">
                      {venue.address}
                      {venue.city && `, ${venue.city}`}
                    </div>
                  </div>
                )}
                {venue.capacity && (
                  <div>
                    <div className="text-sm text-muted-foreground mb-1">Capacity</div>
                    <div className="font-medium">{venue.capacity}</div>
                  </div>
                )}
                {venue.contactEmail && (
                  <div>
                    <div className="flex items-center gap-2 text-sm text-muted-foreground mb-1">
                      <Mail className="h-4 w-4" />
                      Contact Email
                    </div>
                    <div className="font-medium">{venue.contactEmail}</div>
                  </div>
                )}
                {venue.website && (
                  <div>
                    <div className="flex items-center gap-2 text-sm text-muted-foreground mb-1">
                      <Globe className="h-4 w-4" />
                      Website
                    </div>
                    <a 
                      href={venue.website} 
                      target="_blank" 
                      rel="noopener noreferrer"
                      className="font-medium hover:underline text-primary"
                    >
                      {venue.website}
                    </a>
                  </div>
                )}
                <div>
                  <div className="text-sm text-muted-foreground mb-1">Total Events</div>
                  <div className="font-medium">{venue.eventCount || 0}</div>
                </div>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Team Management Card */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Users className="h-5 w-5" />
            Team Management
          </CardTitle>
          <CardDescription>
            Manage sub-administrators who can help manage events and operations
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          {/* Add Sub Admin Form */}
          <form onSubmit={handleAddSubAdmin} className="space-y-4">
            <Label htmlFor="new-subadmin">Add Sub Administrator</Label>
            <div className="flex gap-2">
              <Input
                id="new-subadmin"
                type="email"
                placeholder="subadmin@example.com"
                value={newAdminEmail}
                onChange={(e) => setNewAdminEmail(e.target.value)}
                className="flex-1"
              />
              <Button type="submit" disabled={actionLoading}>
                <Plus className="h-4 w-4 mr-2" />
                Add Sub Admin
              </Button>
            </div>
            <p className="text-xs text-muted-foreground">
              Sub admins can create and manage events but cannot modify venue details or manage other admins
            </p>
          </form>

          {/* Current Team List */}
          <div className="space-y-3">
            <Label>Current Team Members</Label>
            
            {venue.admins.length > 0 && (
              <div className="space-y-2">
                <div className="text-sm font-medium text-muted-foreground">Venue Administrators</div>
                {venue.admins.map((admin) => (
                  <div key={admin} className="flex items-center justify-between p-3 border rounded-lg bg-accent/50">
                    <div className="flex items-center gap-2">
                      <Mail className="h-4 w-4 text-muted-foreground" />
                      <span>{admin}</span>
                      <Badge variant="default">Venue Admin</Badge>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {venue.subAdmins.length > 0 && (
              <div className="space-y-2">
                <div className="text-sm font-medium text-muted-foreground">Sub Administrators</div>
                {venue.subAdmins.map((admin) => (
                  <div key={admin} className="flex items-center justify-between p-3 border rounded-lg">
                    <div className="flex items-center gap-2">
                      <Mail className="h-4 w-4 text-muted-foreground" />
                      <span>{admin}</span>
                      <Badge variant="secondary">Sub Admin</Badge>
                    </div>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => handleRemoveAdmin(venue.id, admin, false)}
                      disabled={actionLoading}
                    >
                      <X className="h-4 w-4" />
                    </Button>
                  </div>
                ))}
              </div>
            )}

            {venue.subAdmins.length === 0 && (
              <p className="text-sm text-muted-foreground text-center py-4 border rounded-lg border-dashed">
                No sub administrators added yet
              </p>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}