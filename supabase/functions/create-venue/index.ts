import { serve } from "std/http/server.ts"
import { corsHeaders } from "../_shared/cors.ts"
import { createAdminClient } from "../_shared/supabase.ts"
import { verifyAdminPermission } from "../_shared/permissions.ts"

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const supabase = createAdminClient()
    const authHeader = req.headers.get('Authorization')
    const { data: { user } } = await supabase.auth.getUser(authHeader?.replace('Bearer ', '') ?? '')
    if (!user) throw new Error('Unauthenticated')

    await verifyAdminPermission(supabase, user.id)

    const { name, adminEmail } = await req.json()
    if (!name || !adminEmail) throw new Error('Missing fields')

    const { data, error } = await supabase.from('venues').insert({
        name: name.trim(),
        admins: [adminEmail.trim()],
        created_by: user.id,
        active: true
    }).select().single()

    if (error) throw error

    return new Response(JSON.stringify({ success: true, venueId: data.id }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})