import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.1"

export const verifyScannerPermission = async (
  supabase: SupabaseClient, 
  userId: string, 
  venueId?: string
) => {
  const { data: admin, error } = await supabase
    .from('admins')
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
    .from('admins')
    .select('*')
    .eq('id', userId)
    .single()

  if (error || !admin || !admin.active) {
    throw new Error('Permission denied: Not an admin')
  }

  // Role hierarchy check
  const roleHierarchy = {
    'scanner': 1,
    'venueAdmin': 2,
    'siteAdmin': 3
  }

  if (roleHierarchy[admin.role] < roleHierarchy[requiredRole]) {
    throw new Error(`Permission denied: Requires ${requiredRole} role`)
  }

  return admin
}