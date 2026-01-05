// lib/supabase-server.ts - Server-side Supabase client with service role access

import { createClient, SupabaseClient } from '@supabase/supabase-js';

// Get environment variables
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

// Create a function to get the admin client with proper error handling
function getSupabaseAdmin(): SupabaseClient<any, "public", any> {
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
let _supabaseAdmin: SupabaseClient<any, "public", any> | null = null;

export const supabaseAdmin = new Proxy({} as SupabaseClient<any, "public", any>, {
  get(target, prop, receiver) {
    if (!_supabaseAdmin) {
      _supabaseAdmin = getSupabaseAdmin();
    }
    const value = (_supabaseAdmin as any)[prop];
    return typeof value === 'function' ? value.bind(_supabaseAdmin) : value;
  }
});
