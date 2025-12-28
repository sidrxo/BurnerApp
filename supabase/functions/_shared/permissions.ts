import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.1"

export const verifyScannerPermission = async (
  supabase: SupabaseClient, 
  userId: string, 
  venueId?: string
) => {
  const { data: admin, error } = await supabase
    .from('users')
    .select('*')
    .eq('id', userId)
    .single()

  if (error || !admin || !admin.active) {
    throw new Error('Permission denied: Not a valid scanner')
  }

  // Check role hierarchy
  const userRole = admin.role
  
  // siteAdmin can do anything
  if (userRole === 'siteAdmin') {
    return admin
  }
  
  // venueAdmin can scan any ticket in their venue
  if (userRole === 'venueAdmin') {
    if (!admin.venue_id) {
      throw new Error('Permission denied: venueAdmin missing venue assignment')
    }
    if (venueId && admin.venue_id !== venueId) {
      throw new Error('Permission denied: Invalid venue access')
    }
    return admin
  }
  
  // scanner can only scan tickets in their specific venue
  if (userRole === 'scanner') {
    if (!admin.venue_id) {
      throw new Error('Permission denied: Scanner missing venue assignment')
    }
    if (!venueId) {
      throw new Error('Permission denied: Ticket venue not specified')
    }
    if (admin.venue_id !== venueId) {
      throw new Error('Permission denied: Scanner not authorized for this venue')
    }
    return admin
  }
  
  throw new Error('Permission denied: Invalid role')
}

export const verifyAdminPermission = async (
  supabase: SupabaseClient,
  userId: string,
  requiredRole: 'siteAdmin' | 'venueAdmin' = 'siteAdmin'
) => {
  const { data: admin, error } = await supabase
    .from('users')
    .select('*')
    .eq('id', userId)
    .single()

  if (error || !admin || !admin.active) {
    throw new Error('Permission denied: Not an admin')
  }

  // Role hierarchy check
  const roleHierarchy = {
    'scanner': 1,
    'organiser': 2,
    'venueAdmin': 2,
    'subAdmin': 2,
    'siteAdmin': 3
  }

  if (roleHierarchy[admin.role] < roleHierarchy[requiredRole]) {
    throw new Error(`Permission denied: Requires ${requiredRole} role`)
  }

  return admin
}

// Verify organizer has access to a specific venue
export const verifyOrganizerVenueAccess = async (
  supabase: SupabaseClient,
  userId: string,
  venueId: string
) => {
  const { data: admin, error } = await supabase
    .from('users')
    .select('*')
    .eq('id', userId)
    .single()

  if (error || !admin || !admin.active) {
    throw new Error('Permission denied: Not an admin')
  }

  // siteAdmin has access to all venues
  if (admin.role === 'siteAdmin') {
    return admin
  }

  // venueAdmin/subAdmin have access to their assigned venue
  if (admin.role === 'venueAdmin' || admin.role === 'subAdmin') {
    if (admin.venue_id === venueId) {
      return admin
    }
    throw new Error('Permission denied: Invalid venue access')
  }

  // organiser must have venue assigned via organizer_venues table
  if (admin.role === 'organiser') {
    const { data: assignment, error: assignmentError } = await supabase
      .from('organizer_venues')
      .select('id')
      .eq('organizer_id', userId)
      .eq('venue_id', venueId)
      .single()

    if (assignmentError || !assignment) {
      throw new Error('Permission denied: Organizer not authorized for this venue')
    }

    return admin
  }

  throw new Error('Permission denied: Invalid role for venue access')
}

// Get all venues accessible to an organizer
export const getOrganizerVenues = async (
  supabase: SupabaseClient,
  userId: string
) => {
  const { data: admin, error } = await supabase
    .from('users')
    .select('*')
    .eq('id', userId)
    .single()

  if (error || !admin || !admin.active) {
    throw new Error('Permission denied: Not an admin')
  }

  if (admin.role !== 'organiser') {
    throw new Error('User is not an organiser')
  }

  const { data: venues, error: venuesError } = await supabase
    .from('organizer_venues')
    .select('venue_id')
    .eq('organizer_id', userId)

  if (venuesError) {
    throw venuesError
  }

  return venues.map(v => v.venue_id)
}