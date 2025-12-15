import { serve } from "std/http/server.ts"
import { corsHeaders } from "../_shared/cors.ts"
import { createAdminClient } from "../_shared/supabase.ts"

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const supabase = createAdminClient()
    const authHeader = req.headers.get('Authorization')
    const { data: { user } } = await supabase.auth.getUser(authHeader?.replace('Bearer ', '') ?? '')
    if (!user) throw new Error('Unauthenticated')

    const { ticketId, recipientEmail } = await req.json()
    const normalizedEmail = recipientEmail.toLowerCase().trim()

    const { data: ticket } = await supabase.from('tickets').select('*').eq('id', ticketId).single()
    if (!ticket) throw new Error('Ticket not found')
    if (ticket.user_id !== user.id) throw new Error('Permission denied')
    if (ticket.status !== 'confirmed') throw new Error('Invalid ticket status')

    const { data: { users } } = await supabase.auth.admin.listUsers()
    const recipient = users.find(u => u.email?.toLowerCase() === normalizedEmail)
    if (!recipient) throw new Error('Recipient must have a Burner account')
    if (recipient.id === user.id) throw new Error('Cannot transfer to self')

    const { data: existing } = await supabase.from('tickets').select('id')
      .eq('event_id', ticket.event_id)
      .eq('user_id', recipient.id)
      .eq('status', 'confirmed')
    if (existing?.length > 0) throw new Error('Recipient already has a ticket')

    await supabase.from('tickets').update({
        user_id: recipient.id,
        transferred_from: user.id,
        transferred_at: new Date().toISOString()
      }).eq('id', ticketId)

    return new Response(JSON.stringify({ success: true, message: `Transferred to ${normalizedEmail}` }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})