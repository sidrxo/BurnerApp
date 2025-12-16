import { useEffect, useState, useMemo } from "react";
import { supabase } from "@/lib/supabase";
import { useAuth } from "@/components/useAuth";
import { toast } from "sonner";

export type Venue = {
  id: string;
  name: string;
  admins: string[];
  subAdmins: string[];
  address?: string;
  city?: string;
  latitude?: number;
  longitude?: number;
  capacity?: number;
  contactEmail?: string;
  website?: string;
  active?: boolean;
  eventCount?: number;
};

export type CreateVenueForm = {
  name: string;
  adminEmail: string;
};

export function useVenuesData() {
  const { user, loading } = useAuth();
  const [venues, setVenues] = useState<Venue[]>([]);
  const [newAdminEmail, setNewAdminEmail] = useState("");
  const [actionLoading, setActionLoading] = useState(false);
  const [newVenueName, setNewVenueName] = useState("");
  const [newVenueAdminEmail, setNewVenueAdminEmail] = useState("");
  const [newVenueAddress, setNewVenueAddress] = useState("");
  const [newVenueCity, setNewVenueCity] = useState("");
  const [newVenueLatitude, setNewVenueLatitude] = useState<string>("");
  const [newVenueLongitude, setNewVenueLongitude] = useState<string>("");
  const [newVenueCapacity, setNewVenueCapacity] = useState<string>("");
  const [newVenueContactEmail, setNewVenueContactEmail] = useState("");
  const [newVenueWebsite, setNewVenueWebsite] = useState("");
  const [showCreateVenueDialog, setShowCreateVenueDialog] = useState(false);
  const [sortBy, setSortBy] = useState<string>("name-asc");

  useEffect(() => {
    if (!loading && user) {
      fetchVenues();
    }
  }, [user, loading]);

  const fetchVenues = async () => {
    try {
      let query = supabase
        .from('venues')
        .select('*');

      // Performance: Only fetch what the user needs based on role
      if (user && user.role === "venueAdmin" && user.venueId) {
        // venueAdmin only needs their own venue
        query = query.eq('id', user.venueId);
      }

      const { data, error } = await query;

      if (error) throw error;

      const fetched: Venue[] = (data || []).map((venue: any) => ({
        id: venue.id,
        name: venue.name,
        admins: venue.admins || [],
        subAdmins: venue.sub_admins || [],
        address: venue.address,
        city: venue.city,
        latitude: venue.coordinates?.latitude,
        longitude: venue.coordinates?.longitude,
        capacity: venue.capacity,
        contactEmail: venue.contact_email,
        website: venue.website,
        active: venue.active,
        eventCount: venue.event_count,
      }));

      setVenues(fetched);
    } catch (err) {
      console.error(err);
      toast.error("Failed to fetch venues");
    }
  };

  const handleCreateVenueWithAdmin = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!newVenueName.trim() || !newVenueAdminEmail.trim()) {
      toast.error("Please fill in all fields");
      return;
    }

    // Basic email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(newVenueAdminEmail)) {
      toast.error("Please enter a valid email address");
      return;
    }

    setActionLoading(true);
    try {
      // Use Supabase Edge Function to create venue (it handles admin setup too)
      const { data, error } = await supabase.functions.invoke('create-venue', {
        body: {
          name: newVenueName.trim(),
          adminEmail: newVenueAdminEmail.trim(),
        },
      });

      if (error) throw error;

      // Update the venue with additional details if provided
      if (data?.venueId) {
        const coordinates = (newVenueLatitude && newVenueLongitude)
          ? { latitude: Number(newVenueLatitude), longitude: Number(newVenueLongitude) }
          : null;

        const updates: any = {};
        if (newVenueAddress.trim()) updates.address = newVenueAddress.trim();
        if (newVenueCity.trim()) updates.city = newVenueCity.trim();
        if (coordinates) updates.coordinates = coordinates;
        if (newVenueCapacity) updates.capacity = Number(newVenueCapacity);
        if (newVenueContactEmail.trim()) updates.contact_email = newVenueContactEmail.trim();
        if (newVenueWebsite.trim()) updates.website = newVenueWebsite.trim();

        if (Object.keys(updates).length > 0) {
          await supabase
            .from('venues')
            .update(updates)
            .eq('id', data.venueId);
        }
      }

      toast.success(`Venue "${newVenueName}" created with admin ${newVenueAdminEmail}`);
      setNewVenueName("");
      setNewVenueAdminEmail("");
      setNewVenueAddress("");
      setNewVenueCity("");
      setNewVenueLatitude("");
      setNewVenueLongitude("");
      setNewVenueCapacity("");
      setNewVenueContactEmail("");
      setNewVenueWebsite("");
      setShowCreateVenueDialog(false);
      fetchVenues();
    } catch (err: any) {
      console.error(err);
      toast.error(err.message || "Failed to create venue");
    } finally {
      setActionLoading(false);
    }
  };

  const handleRemoveVenue = async (venueId: string) => {
    const venue = venues.find(v => v.id === venueId);
    if (!venue) return;

    setActionLoading(true);
    try {
      // Delete the venue
      const { error: venueError } = await supabase
        .from('venues')
        .delete()
        .eq('id', venueId);

      if (venueError) throw venueError;

      // Reset all admins associated with this venue
      const { error: adminsError } = await supabase
        .from('admins')
        .update({ role: 'user', venue_id: null })
        .eq('venue_id', venueId);

      if (adminsError) console.warn("Error resetting admins:", adminsError);

      toast.success(`Venue "${venue.name}" and all associated admins removed successfully`);
      fetchVenues();
    } catch (err) {
      console.error(err);
      toast.error("Failed to remove venue");
    } finally {
      setActionLoading(false);
    }
  };

  const handleAddAdmin = async (venueId: string, email: string, role: 'venueAdmin' | 'subAdmin') => {
    if (!email.trim()) {
      toast.error("Please enter an email address");
      return;
    }

    // Basic email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      toast.error("Please enter a valid email address");
      return;
    }

    setActionLoading(true);
    try {
      if (!user) throw new Error("User not found");

      // Check if user exists in admins table
      const { data: existingAdmin } = await supabase
        .from('admins')
        .select('id, email')
        .eq('email', email.trim())
        .single();

      if (existingAdmin) {
        // Update existing admin
        const { error } = await supabase
          .from('admins')
          .update({
            role: role,
            venue_id: venueId,
            active: true,
          })
          .eq('email', email.trim());

        if (error) throw error;
      } else {
        // Create new admin entry
        const { error } = await supabase
          .from('admins')
          .insert([{
            email: email.trim(),
            role: role,
            venue_id: venueId,
            active: true,
            created_at: new Date().toISOString(),
          }]);

        if (error) throw error;
      }

      // Update venue's admin array
      const venue = venues.find((v) => v.id === venueId);
      if (!venue) throw new Error("Venue not found");

      const arrayField = role === "venueAdmin" ? "admins" : "sub_admins";
      const currentArray = role === "venueAdmin" ? venue.admins : venue.subAdmins;

      // Add email to array if not already present
      if (!currentArray.includes(email.trim())) {
        const updatedArray = [...currentArray, email.trim()];

        const { error } = await supabase
          .from('venues')
          .update({ [arrayField]: updatedArray })
          .eq('id', venueId);

        if (error) throw error;
      }

      const roleType = role === "venueAdmin" ? "venue admin" : "sub-admin";
      toast.success(`${roleType} added successfully`);
      setNewAdminEmail("");
      fetchVenues();
    } catch (err) {
      console.error(err);
      toast.error("Failed to add admin");
    } finally {
      setActionLoading(false);
    }
  };

  const handleRemoveAdmin = async (venueId: string, email: string, isVenueAdmin: boolean) => {
    setActionLoading(true);
    try {
      const venue = venues.find((v) => v.id === venueId);
      if (!venue) throw new Error("Venue not found");

      // Remove from venue's array
      const arrayField = isVenueAdmin ? "admins" : "sub_admins";
      const currentArray = isVenueAdmin ? venue.admins : venue.subAdmins;
      const updatedArray = currentArray.filter(e => e !== email);

      const { error: venueError } = await supabase
        .from('venues')
        .update({ [arrayField]: updatedArray })
        .eq('id', venueId);

      if (venueError) throw venueError;

      // Update admin role in admins table
      const { error: adminError } = await supabase
        .from('admins')
        .update({
          role: 'user',
          venue_id: null,
        })
        .eq('email', email);

      if (adminError) console.warn("Error updating admin:", adminError);

      const roleType = isVenueAdmin ? "venue admin" : "sub-admin";
      toast.success(`${roleType} removed successfully`);
      fetchVenues();
    } catch (err) {
      console.error(err);
      toast.error("Failed to remove admin");
    } finally {
      setActionLoading(false);
    }
  };

  const handleUpdateVenue = async (
    venueId: string,
    updates: Partial<Venue>
  ) => {
    setActionLoading(true);
    try {
      // Convert camelCase to snake_case and prepare update object
      const updateData: any = {};
      if (updates.name !== undefined) updateData.name = updates.name;
      if (updates.address !== undefined) updateData.address = updates.address;
      if (updates.city !== undefined) updateData.city = updates.city;
      if (updates.capacity !== undefined) updateData.capacity = updates.capacity;
      if (updates.contactEmail !== undefined) updateData.contact_email = updates.contactEmail;
      if (updates.website !== undefined) updateData.website = updates.website;
      if (updates.active !== undefined) updateData.active = updates.active;

      // Handle coordinates update
      if (updates.latitude !== undefined && updates.longitude !== undefined) {
        if (updates.latitude && updates.longitude) {
          updateData.coordinates = { latitude: updates.latitude, longitude: updates.longitude };
        } else {
          updateData.coordinates = null;
        }
      }

      updateData.updated_at = new Date().toISOString();

      const { error } = await supabase
        .from('venues')
        .update(updateData)
        .eq('id', venueId);

      if (error) throw error;

      toast.success("Venue updated successfully");
      fetchVenues();
    } catch (err) {
      console.error(err);
      toast.error("Failed to update venue");
    } finally {
      setActionLoading(false);
    }
  };

  const resetCreateForm = () => {
    setNewVenueName("");
    setNewVenueAdminEmail("");
    setNewVenueAddress("");
    setNewVenueCity("");
    setNewVenueLatitude("");
    setNewVenueLongitude("");
    setNewVenueCapacity("");
    setNewVenueContactEmail("");
    setNewVenueWebsite("");
  };

  const sortedVenues = useMemo(() => {
    const result = [...venues];
    result.sort((a, b) => {
      switch (sortBy) {
        case "name-asc":
          return (a.name || "").localeCompare(b.name || "");
        case "name-desc":
          return (b.name || "").localeCompare(a.name || "");
        case "capacity-asc":
          return (a.capacity || 0) - (b.capacity || 0);
        case "capacity-desc":
          return (b.capacity || 0) - (a.capacity || 0);
        case "events-asc":
          return (a.eventCount || 0) - (b.eventCount || 0);
        case "events-desc":
          return (b.eventCount || 0) - (a.eventCount || 0);
        case "city":
          return (a.city || "").localeCompare(b.city || "");
        default:
          return 0;
      }
    });
    return result;
  }, [venues, sortBy]);

  return {
    user,
    loading,
    venues: sortedVenues,
    newAdminEmail,
    setNewAdminEmail,
    actionLoading,
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
    showCreateVenueDialog,
    setShowCreateVenueDialog,
    sortBy,
    setSortBy,
    fetchVenues,
    handleCreateVenueWithAdmin,
    handleRemoveVenue,
    handleAddAdmin,
    handleRemoveAdmin,
    handleUpdateVenue,
    resetCreateForm
  };
}
