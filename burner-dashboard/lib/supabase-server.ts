// lib/supabase-server.ts - Server-side Supabase client with service role access

import { createClient } from '@supabase/supabase-js';

// Get environment variables
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

// Create a function to get the admin client with proper error handling
function getSupabaseAdmin() {
  if (!supabaseUrl) {
    console.error('❌ Missing NEXT_PUBLIC_SUPABASE_URL environment variable');
    throw new Error('Missing NEXT_PUBLIC_SUPABASE_URL environment variable');
  }

  if (!supabaseServiceRoleKey) {
    console.error('❌ Missing SUPABASE_SERVICE_ROLE_KEY environment variable');
    throw new Error('Missing SUPABASE_SERVICE_ROLE_KEY environment variable');
  }

  return createClient(
    supabaseUrl,
    supabaseServiceRoleKey,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    }
  );
}

// Create Supabase client with service role key for server-side operations
// This bypasses RLS and should only be used in server actions/API routes
// Use lazy initialization to avoid errors at module import time
let _supabaseAdmin: ReturnType<typeof createClient> | null = null;

export const supabaseAdmin = new Proxy({} as ReturnType<typeof createClient>, {
  get(target, prop) {
    if (!_supabaseAdmin) {
      _supabaseAdmin = getSupabaseAdmin();
    }
    return (_supabaseAdmin as any)[prop];
  }
});
