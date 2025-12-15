import { SupabaseClient } from '@supabase/supabase-js'

export const verifyScannerPermission = async (supabase: SupabaseClient, userId: string, venueId?: string) => {
  const { data: scanner, error } = await supabase
    .from('scanners')
    .select('*')
    .eq('id', userId)
    .single()

  if (error || !scanner || !scanner.active) {
    throw new Error('Permission denied: Not a valid scanner')
  }

  if (venueId && scanner.venue_id && scanner.venue_id !== venueId) {
    throw new Error('Permission denied: Invalid venue access')
  }

  return scanner
}

export const verifyAdminPermission = async (supabase: SupabaseClient, userId: string) => {
  const { data: admin, error } = await supabase
    .from('admins')
    .select('*')
    .eq('id', userId)
    .single()

  if (error || !admin || !admin.active) {
    throw new Error('Permission denied: Not an admin')
  }
  return admin
}