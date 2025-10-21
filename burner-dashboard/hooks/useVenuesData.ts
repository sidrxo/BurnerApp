import { useEffect, useState } from "react";
import { collection, doc, getDocs, updateDoc, setDoc, addDoc, deleteDoc, arrayUnion, arrayRemove, query, where } from "firebase/firestore";
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
  const [newVenueCapacity, setNewVenueCapacity] = useState<string>("");
  const [newVenueContactEmail, setNewVenueContactEmail] = useState("");
  const [newVenueWebsite, setNewVenueWebsite] = useState("");
  const [showCreateVenueDialog, setShowCreateVenueDialog] = useState(false);

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
      // Create the venue first
      const venueRef = await addDoc(collection(db, "venues"), {
        name: newVenueName.trim(),
        address: newVenueAddress.trim() || null,
        city: newVenueCity.trim() || null,
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

  const handleAddAdmin = async (venueId: string) => {
    if (!newAdminEmail.trim()) {
      toast.error("Please enter an email address");
      return;
    }

    // Basic email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(newAdminEmail)) {
      toast.error("Please enter a valid email address");
      return;
    }

    setActionLoading(true);
    try {
      if (!user) throw new Error("User not found");

      // Lookup user by email using query instead of loading all users
      const usersQuery = query(
        collection(db, "users"),
        where("email", "==", newAdminEmail.trim())
      );
      const usersSnapshot = await getDocs(usersQuery);

      const newRole = user.role === "siteAdmin" ? "venueAdmin" : "subAdmin";

      if (!usersSnapshot.empty) {
        // User exists, update their role
        const userDoc = usersSnapshot.docs[0];
        await updateDoc(userDoc.ref, {
          role: newRole,
          venueId: venueId
        });
      } else {
        // Create new user document
        const newUserRef = doc(db, "users", newAdminEmail.trim());
        await setDoc(newUserRef, {
          email: newAdminEmail.trim(),
          role: newRole,
          venueId: venueId
        });
      }

      const venueRef = doc(db, "venues", venueId);
      const venue = venues.find((v) => v.id === venueId);
      if (!venue) throw new Error("Venue not found");

      const arrayField = user.role === "siteAdmin" ? "admins" : "subAdmins";
      await updateDoc(venueRef, {
        [arrayField]: arrayUnion(newAdminEmail.trim())
      });

      const roleType = user.role === "siteAdmin" ? "venue admin" : "sub-admin";
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

  const resetCreateForm = () => {
    setNewVenueName("");
    setNewVenueAdminEmail("");
    setNewVenueAddress("");
    setNewVenueCity("");
    setNewVenueCapacity("");
    setNewVenueContactEmail("");
    setNewVenueWebsite("");
  };

  return {
    user,
    loading,
    venues,
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
    newVenueCapacity,
    setNewVenueCapacity,
    newVenueContactEmail,
    setNewVenueContactEmail,
    newVenueWebsite,
    setNewVenueWebsite,
    showCreateVenueDialog,
    setShowCreateVenueDialog,
    fetchVenues,
    handleCreateVenueWithAdmin,
    handleRemoveVenue,
    handleAddAdmin,
    handleRemoveAdmin,
    resetCreateForm
  };
}