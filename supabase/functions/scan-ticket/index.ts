import { serve } from "std/http/server.ts"
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

    const { ticketId } = await req.json()

    const { data: ticket, error: ticketError } = await supabase
      .from('tickets')
      .select('*, events(venue_id)')
      .eq('id', ticketId)
      .single()

    if (ticketError || !ticket) throw new Error('Ticket not found')

    await verifyScannerPermission(supabase, user.id, ticket.events?.venue_id)

    if (ticket.status === 'used') {
        return new Response(JSON.stringify({
            success: false,
            message: "Ticket already used",
            ticketStatus: "used",
            scannedBy: ticket.scanned_by
        }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    if (ticket.status === 'cancelled') {
        return new Response(JSON.stringify({ success: false, message: "Ticket cancelled" }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    await supabase.from('tickets').update({
        status: 'used',
        used_at: new Date().toISOString(),
        scanned_by: user.id,
        scanned_by_email: user.email
    }).eq('id', ticketId)

    return new Response(JSON.stringify({
        success: true,
        message: "Ticket validated",
        ticket: {
            id: ticketId,
            status: "used",
            scannedAt: new Date().toISOString()
        }
    }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })

  } catch (error) {
    return new Response(JSON.stringify({ success: false, message: error.message }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})