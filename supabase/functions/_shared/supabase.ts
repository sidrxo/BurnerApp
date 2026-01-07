import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.1"

export const createAdminClient = () => {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const serviceRoleKey = Deno.env.get('SERVICE_ROLE_KEY')

  if (!supabaseUrl) {
    throw new Error('SUPABASE_URL environment variable is required')
  }

  if (!serviceRoleKey) {
    throw new Error('SERVICE_ROLE_KEY environment variable is required')
  }

  // Production validation
  const isProduction = Deno.env.get('DENO_DEPLOYMENT_ID') !== undefined
  if (isProduction && !supabaseUrl.startsWith('https://')) {
    throw new Error('SUPABASE_URL must use HTTPS in production')
  }

  return createClient(
    supabaseUrl,
    serviceRoleKey,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    }
  )
}