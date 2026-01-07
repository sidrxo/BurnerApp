import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { corsHeaders } from "../_shared/cors.ts"
import { createAdminClient } from "../_shared/supabase.ts"
import { verifyScannerPermission } from "../_shared/permissions.ts"

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const supabase = createAdminClient()
    const authHeader = req.headers.get('Authorization')
    const { data: { user } } = await supabase.auth.getUser(authHeader?.replace('Bearer ', '') ?? '')
    if (!user) throw new Error('Unauthenticated')

    await verifyScannerPermission(supabase, user.id)

    const { limit = 50 } = await req.json().catch(() => ({}))

    const { data: scans } = await supabase
        .from('tickets')
        .select('id, event_name, venue, ticket_number, used_at, user_name')
        .eq('scanned_by', user.id)
        .order('used_at', { ascending: false })
        .limit(limit)

    return new Response(JSON.stringify({ success: true, scans }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})