import { useEffect, useState, useMemo } from "react";
import { collection, doc, getDocs, updateDoc, setDoc, addDoc, deleteDoc, arrayUnion, arrayRemove, query, where, GeoPoint } from "firebase/firestore";
import { db } from "@/lib/firebase";
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
      let snapshot;

      // Optimize query based on role - only fetch what the user needs
      if (user && user.role === "venueAdmin" && user.venueId) {
        // venueAdmin only needs their own venue
        const venueDoc = await getDocs(
          query(collection(db, "venues"), where("__name__", "==", user.venueId))
        );
        snapshot = venueDoc;
      } else {
        // siteAdmin and others can see all venues
        snapshot = await getDocs(collection(db, "venues"));
      }

      const fetched: Venue[] = [];
      snapshot.forEach((doc) => {
        const data = doc.data();
        fetched.push({
          id: doc.id,
          name: data.name,
          admins: data.admins || [],
          subAdmins: data.subAdmins || [],
          address: data.address,
          city: data.city,
          latitude: data.coordinates?.latitude,
          longitude: data.coordinates?.longitude,
          capacity: data.capacity,
          contactEmail: data.contactEmail,
          website: data.website,
          active: data.active,
          eventCount: data.eventCount,
        });
      });

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
      // Prepare coordinates as GeoPoint if both latitude and longitude are provided
      const coordinates = (newVenueLatitude && newVenueLongitude)
        ? new GeoPoint(Number(newVenueLatitude), Number(newVenueLongitude))
        : null;

      // Create the venue first
      const venueRef = await addDoc(collection(db, "venues"), {
        name: newVenueName.trim(),
        address: newVenueAddress.trim() || null,
        city: newVenueCity.trim() || null,
        coordinates: coordinates,
        capacity: newVenueCapacity ? Number(newVenueCapacity) : null,
        contactEmail: newVenueContactEmail.trim() || null,
        website: newVenueWebsite.trim() || null,
        admins: [newVenueAdminEmail.trim()],
        subAdmins: [],
        createdAt: new Date(),
        createdBy: user?.uid ?? null,
        active: true,
        eventCount: 0,
      });

      // Check if user already exists using query instead of loading all users
      const usersQuery = query(
        collection(db, "users"),
        where("email", "==", newVenueAdminEmail.trim())
      );
      const usersSnapshot = await getDocs(usersQuery);

      // Create or update user document
      if (!usersSnapshot.empty) {
        // User exists, update their role
        const userDoc = usersSnapshot.docs[0];
        await updateDoc(userDoc.ref, {
          role: "venueAdmin",
          venueId: venueRef.id
        });
      } else {
        // Create new user document
        const newUserRef = doc(db, "users", newVenueAdminEmail.trim());
        await setDoc(newUserRef, {
          email: newVenueAdminEmail.trim(),
          role: "venueAdmin",
          venueId: venueRef.id
        });
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
    } catch (err) {
      console.error(err);
      toast.error("Failed to create venue");
    } finally {
      setActionLoading(false);
    }
  };

  const handleRemoveVenue = async (venueId: string) => {
    const venue = venues.find(v => v.id === venueId);
    if (!venue) return;
    
    setActionLoading(true);
    try {
      await deleteDoc(doc(db, "venues", venueId));

      // Reset all users associated with this venue using query
      const usersQuery = query(
        collection(db, "users"),
        where("venueId", "==", venueId)
      );
      const usersSnapshot = await getDocs(usersQuery);

      const updatePromises = usersSnapshot.docs.map((docSnap) =>
        updateDoc(docSnap.ref, { role: "user", venueId: null })
      );
      await Promise.all(updatePromises);

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

      // Lookup user by email using query instead of loading all users
      const usersQuery = query(
        collection(db, "users"),
        where("email", "==", email.trim())
      );
      const usersSnapshot = await getDocs(usersQuery);

      if (!usersSnapshot.empty) {
        // User exists, update their role
        const userDoc = usersSnapshot.docs[0];
        await updateDoc(userDoc.ref, {
          role: role,
          venueId: venueId
        });
      } else {
        // Create new user document
        const newUserRef = doc(db, "users", email.trim());
        await setDoc(newUserRef, {
          email: email.trim(),
          role: role,
          venueId: venueId
        });
      }

      const venueRef = doc(db, "venues", venueId);
      const venue = venues.find((v) => v.id === venueId);
      if (!venue) throw new Error("Venue not found");

      const arrayField = role === "venueAdmin" ? "admins" : "subAdmins";
      await updateDoc(venueRef, {
        [arrayField]: arrayUnion(email.trim())
      });

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
      // Update venue's admin/subAdmin array
      const venueRef = doc(db, "venues", venueId);
      const venue = venues.find((v) => v.id === venueId);
      if (!venue) throw new Error("Venue not found");

      const arrayField = isVenueAdmin ? "admins" : "subAdmins";
      await updateDoc(venueRef, {
        [arrayField]: arrayRemove(email)
      });

      // Update user's role in /users using query instead of loading all users
      const usersQuery = query(
        collection(db, "users"),
        where("email", "==", email)
      );
      const usersSnapshot = await getDocs(usersQuery);

      if (!usersSnapshot.empty) {
        const userDoc = usersSnapshot.docs[0];
        await updateDoc(userDoc.ref, {
          role: "user",
          venueId: null
        });
      }

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
      const venueRef = doc(db, "venues", venueId);

      // Filter out undefined values and prepare update object
      const updateData: any = {};
      if (updates.name !== undefined) updateData.name = updates.name;
      if (updates.address !== undefined) updateData.address = updates.address;
      if (updates.city !== undefined) updateData.city = updates.city;
      if (updates.capacity !== undefined) updateData.capacity = updates.capacity;
      if (updates.contactEmail !== undefined) updateData.contactEmail = updates.contactEmail;
      if (updates.website !== undefined) updateData.website = updates.website;
      if (updates.active !== undefined) updateData.active = updates.active;

      // Handle coordinates update
      if (updates.latitude !== undefined && updates.longitude !== undefined) {
        if (updates.latitude && updates.longitude) {
          updateData.coordinates = new GeoPoint(updates.latitude, updates.longitude);
        } else {
          updateData.coordinates = null;
        }
      }

      await updateDoc(venueRef, {
        ...updateData,
        updatedAt: new Date()
      });

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