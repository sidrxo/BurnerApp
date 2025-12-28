"use client";

import { useState, useEffect } from "react";
import { useAuth } from "@/components/useAuth";
import { supabase } from "@/lib/supabase";
import { toast } from "sonner";

export interface Admin {
  id: string;
  email: string;
  name: string;
  role: 'venueAdmin' | 'subAdmin' | 'siteAdmin' | 'organiser';
  venueId?: string;
  created_at?: string;
  last_login?: string;
  active: boolean;
  needs_password_reset?: boolean;
}

export interface Scanner {
  id: string;
  email: string;
  name: string;
  venue_id?: string | null;
  active: boolean;
  created_at?: string;
  last_active_at?: string | null;
  // Legacy camelCase for backward compatibility
  venueId?: string | null;
  createdAt?: string;
  lastActiveAt?: string | null;
}

export interface Venue {
  id: string;
  name: string;
  address?: string;
  city?: string;
  admins: string[];
  subAdmins: string[];
}

export interface CreateAdminData {
  email: string;
  name: string;
  role: 'venueAdmin' | 'subAdmin' | 'siteAdmin' | 'organiser';
  venueId?: string;
  password?: string;
}

export interface CreateScannerData {
  email: string;
  name: string;
  venueId?: string | null;
}

export function useAdminManagement() {
  const { user, loading: authLoading, refreshUser } = useAuth();
  const [admins, setAdmins] = useState<Admin[]>([]);
  const [venues, setVenues] = useState<Venue[]>([]);
  const [scanners, setScanners] = useState<Scanner[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!authLoading && user && user.role === "siteAdmin") {
      loadData();
    } else if (!authLoading && user && user.role !== "siteAdmin") {
      setLoading(false);
    }
  }, [user, authLoading]);

  const loadData = async () => {
    setLoading(true);
    try {
      // Load venues
      const { data: venuesData, error: venuesError } = await supabase
        .from('venues')
        .select('id, name, address, city, admins, sub_admins')
        .order('name', { ascending: true });

      if (venuesError) throw venuesError;

      setVenues((venuesData || []).map(v => ({
        ...v,
        subAdmins: v.sub_admins || []
      })));

      // Load admins (users with admin roles) with RLS protection
      const { data: adminsData, error: adminsError } = await supabase
        .from('users')
        .select('*, name:display_name')
        .in('role', ['siteAdmin', 'venueAdmin', 'subAdmin', 'organiser'])
        .order('created_at', { ascending: false });

      if (adminsError) throw adminsError;

      setAdmins((adminsData || []).map(admin => ({
        ...admin,
        name: admin.display_name || admin.name,
        venueId: admin.venue_id
      })));

      // Load scanners (users with scanner role)
      const { data: scannersData } = await supabase
        .from('users')
        .select('*, name:display_name')
        .eq('role', 'scanner')
        .order('created_at', { ascending: false });

      setScanners((scannersData || []).map(scanner => ({
        id: scanner.id,
        email: scanner.email,
        name: scanner.display_name || scanner.name || 'Scanner',
        venue_id: scanner.venue_id ?? null,
        active: scanner.active !== false,
        created_at: scanner.created_at,
        last_active_at: scanner.last_active_at ?? null,
        // Legacy camelCase for backward compatibility
        venueId: scanner.venue_id ?? null,
        createdAt: scanner.created_at,
        lastActiveAt: scanner.last_active_at ?? null,
      })));

    } catch (error) {
      console.error("Error loading admin management data:", error);
      toast.error("Failed to load admin data");
    } finally {
      setLoading(false);
    }
  };

  const createAdmin = async (adminData: CreateAdminData) => {
    try {
      setLoading(true);

      // If password is provided, use the Edge Function to create auth user + admin entry
      if (adminData.password) {
        const { data, error } = await supabase.functions.invoke('create-admin', {
          body: {
            email: adminData.email.trim(),
            password: adminData.password,
            display_name: adminData.name.trim(),
            role: adminData.role,
            venueId: adminData.venueId || null,
          },
        });

        if (error) throw error;
        if (data?.error) throw new Error(data.error);

        toast.success("Admin created successfully with authentication credentials.");

        // Refresh user permissions
        await refreshUser();

        // Reload data
        await loadData();

        return { success: true };
      }

      // Fallback: Create admin entry in database only (without auth user)
      // This is for backward compatibility or manual auth user creation

      // Check if admin already exists
      const { data: existing } = await supabase
        .from('users')
        .select('id')
        .eq('email', adminData.email.trim())
        .single();

      if (existing) {
        toast.error("Admin with this email already exists");
        return { success: false, error: "Admin already exists" };
      }

      // Create admin entry in database
      const { data, error } = await supabase
        .from('users')
        .insert([{
          email: adminData.email.trim(),
          display_name: adminData.name.trim(),
          role: adminData.role,
          venue_id: adminData.venueId || null,
          active: true,
          created_at: new Date().toISOString(),
        }])
        .select()
        .single();

      if (error) throw error;

      toast.success("Admin entry created. Auth user needs to be created separately.");

      // Refresh user permissions
      await refreshUser();

      // Reload data
      await loadData();

      return { success: true };
    } catch (error: any) {
      console.error("Error creating admin:", error);
      let errorMessage = error.message || "Failed to create admin";
      toast.error(errorMessage);
      return { success: false, error: errorMessage };
    } finally {
      setLoading(false);
    }
  };

  const updateAdmin = async (adminId: string, updates: Partial<Admin>) => {
    try {
      setLoading(true);

      const updateData: any = {};
      if (updates.role) updateData.role = updates.role;
      if (typeof updates.active === 'boolean') updateData.active = updates.active;
      if (updates.venueId !== undefined) updateData.venue_id = updates.venueId;
      if (updates.name) updateData.display_name = updates.name;
      if (updates.email) updateData.email = updates.email;

      const { error } = await supabase
        .from('users')
        .update(updateData)
        .eq('id', adminId);

      if (error) throw error;

      toast.success("Admin updated successfully");

      // Refresh user permissions
      await refreshUser();

      // Reload data
      await loadData();
    } catch (error: any) {
      console.error("Error updating admin:", error);
      let errorMessage = error.message || "Failed to update admin";
      toast.error(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const deleteAdmin = async (adminId: string) => {
    try {
      setLoading(true);

      // Prevent deleting own account
      if (user && adminId === user.uid) {
        toast.error("Cannot delete your own admin account");
        return;
      }

      // NOTE: This should also delete the auth user
      // TODO: Create 'delete-admin' Edge Function to handle auth deletion
      const { error } = await supabase
        .from('users')
        .delete()
        .eq('id', adminId);

      if (error) throw error;

      toast.success("Admin deleted. Auth user should be cleaned up via backend.");

      // Refresh user permissions
      await refreshUser();

      // Reload data
      await loadData();
    } catch (error: any) {
      console.error("Error deleting admin:", error);
      let errorMessage = error.message || "Failed to delete admin";
      toast.error(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const createVenue = async (name: string, adminEmail: string) => {
    try {
      setLoading(true);

      // Use existing Supabase Edge Function
      const { data, error } = await supabase.functions.invoke('create-venue', {
        body: {
          name: name.trim(),
          adminEmail: adminEmail.trim()
        },
      });

      if (error) throw error;

      toast.success("Venue created successfully");

      // Reload data
      await loadData();

      return { success: true, venueId: data?.venueId };
    } catch (error: any) {
      console.error("Error creating venue:", error);
      let errorMessage = error.message || "Failed to create venue";
      toast.error(errorMessage);
      return { success: false, error: errorMessage };
    } finally {
      setLoading(false);
    }
  };

  const createScanner = async (scannerData: CreateScannerData) => {
    try {
      setLoading(true);

      // NOTE: This requires a Supabase Edge Function to create auth users
      // For now, we'll create the scanner entry in the database
      // TODO: Create 'create-scanner' Edge Function for auth user creation

      // Check if scanner already exists
      const { data: existing } = await supabase
        .from('users')
        .select('id')
        .eq('email', scannerData.email.trim())
        .single();

      if (existing) {
        toast.error("Scanner with this email already exists");
        return { success: false, error: "Scanner already exists" };
      }

      // Create scanner entry in database (scanners are stored in admins table with role='scanner')
      const { data, error } = await supabase
        .from('users')
        .insert([{
          email: scannerData.email.trim(),
          name: scannerData.name.trim(),
          role: 'scanner',
          venue_id: scannerData.venueId || null,
          active: true,
          created_at: new Date().toISOString(),
        }])
        .select()
        .single();

      if (error) throw error;

      toast.success("Scanner created successfully. Auth user needs to be created via backend.");

      // Reload data
      await loadData();

      return { success: true, scannerId: data?.id };
    } catch (error: any) {
      console.error('Error creating scanner:', error);
      let errorMessage = error.message || 'Failed to create scanner';
      toast.error(errorMessage);
      return { success: false, error: errorMessage };
    } finally {
      setLoading(false);
    }
  };

  const updateScanner = async (scannerId: string, updates: Partial<Scanner>) => {
    try {
      setLoading(true);

      const updateData: any = {};
      if (updates.name) updateData.name = updates.name;
      if (updates.email) updateData.email = updates.email;
      if (updates.venue_id !== undefined) updateData.venue_id = updates.venue_id;
      if (typeof updates.active === 'boolean') updateData.active = updates.active;

      const { error } = await supabase
        .from('users')
        .update(updateData)
        .eq('id', scannerId);

      if (error) throw error;

      toast.success("Scanner updated successfully");

      // Reload data
      await loadData();
      return { success: true };
    } catch (error: any) {
      console.error('Error updating scanner:', error);
      let errorMessage = error.message || 'Failed to update scanner';
      toast.error(errorMessage);
      return { success: false, error: errorMessage };
    } finally {
      setLoading(false);
    }
  };

  const deleteScanner = async (scannerId: string) => {
    try {
      setLoading(true);

      // NOTE: This should also delete the auth user
      // TODO: Create 'delete-scanner' Edge Function to handle auth deletion
      const { error } = await supabase
        .from('users')
        .delete()
        .eq('id', scannerId);

      if (error) throw error;

      toast.success("Scanner deleted. Auth user should be cleaned up via backend.");

      // Reload data
      await loadData();
    } catch (error: any) {
      console.error('Error deleting scanner:', error);
      let errorMessage = error.message || 'Failed to delete scanner';
      toast.error(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const manageOrganizerVenues = async (organizerId: string, venueIds: string[]) => {
    try {
      const { data, error } = await supabase.auth.getSession();
      if (error || !data.session) throw new Error('Not authenticated');

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/manage-organizer-venues`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${data.session.access_token}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            action: 'set',
            organizerId: organizerId,
            venueIds: venueIds
          })
        }
      );

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.error || 'Failed to update organizer venues');
      }

      toast.success('Organizer venues updated successfully');
    } catch (error: any) {
      console.error('Error managing organizer venues:', error);
      toast.error(error.message || 'Failed to update organizer venues');
      throw error;
    }
  };

  return {
    user,
    authLoading,
    loading,
    admins,
    venues,
    scanners,
    createAdmin,
    deleteAdmin,
    updateAdmin,
    createVenue,
    createScanner,
    updateScanner,
    deleteScanner,
    manageOrganizerVenues,
    loadData,
    refreshUser
  };
}