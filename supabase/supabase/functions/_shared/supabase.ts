import { createClient } from '@supabase/supabase-js'

export const createAdminClient = () => {
  return createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SERVICE_ROLE_KEY') ?? '', 
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    }
  )
}