import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { corsHeaders } from "../_shared/cors.ts"
import { createAdminClient } from "../_shared/supabase.ts"

serve(async (req) => {
  // Handle CORS preflight request
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createAdminClient()
    
    // 1. Authenticate User
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) throw new Error('Missing Authorization header')
    
    const { data: { user }, error: authError } = await supabase.auth.getUser(authHeader.replace('Bearer ', ''))
    if (authError || !user) {
      console.error("Auth failed:", authError)
      throw new Error('Unauthenticated')
    }

    // 2. Parse Input
    const { ticketId, recipientEmail } = await req.json()
    console.log(`Processing transfer: Ticket ${ticketId} -> ${recipientEmail}`)

    if (!ticketId || !recipientEmail) throw new Error('Missing ticketId or recipientEmail')
    const normalizedEmail = recipientEmail.toLowerCase().trim()

    // 3. Get Ticket & Verify Ownership
    // UPDATED: Query by ticket_id instead of id
    const { data: ticket, error: ticketError } = await supabase
        .from('tickets')
        .select('*') 
        .eq('ticket_id', ticketId)  // CHANGED: from 'id' to 'ticket_id'
        .single()

    if (ticketError || !ticket) {
        console.error("Ticket lookup failed:", ticketError)
        throw new Error('Ticket not found')
    }

    // UPDATED: Use snake_case column name from database
    if (ticket.user_id !== user.id) {  // CHANGED: from 'userId' to 'user_id'
        console.error(`Permission denied. Owner: ${ticket.user_id}, Requestor: ${user.id}`)
        throw new Error('Permission denied: You do not own this ticket')
    }

    if (ticket.status !== 'confirmed') {
        throw new Error(`Invalid ticket status: ${ticket.status}`)
    }

    // 4. Find Recipient (Using Auth Admin API)
    const { data: { users }, error: listUsersError } = await supabase.auth.admin.listUsers({
        page: 1,
        perPage: 1000 
    })

    if (listUsersError) {
        console.error("List users failed:", listUsersError)
        throw new Error('Failed to search for recipient')
    }

    const recipient = users.find(u => u.email?.toLowerCase() === normalizedEmail)

    if (!recipient) {
        throw new Error('Recipient must have a Burner account')
    }

    if (recipient.id === user.id) {
        throw new Error('Cannot transfer ticket to yourself')
    }

    // 5. Check if Recipient already has a ticket
    // UPDATED: Use snake_case column names in query
    const { data: existing } = await supabase
        .from('tickets')
        .select('ticket_id')  // CHANGED: from 'id' to 'ticket_id'
        .eq('event_id', ticket.event_id)  // CHANGED: from 'eventId' to 'event_id'
        .eq('user_id', recipient.id)      // CHANGED: from 'userId' to 'user_id'
        .eq('status', 'confirmed')
        .maybeSingle()

    if (existing) throw new Error('Recipient already has a ticket for this event')

    // 6. Perform Transfer
    // UPDATED: Use snake_case column names for update
    const { error: updateError } = await supabase
        .from('tickets')
        .update({
            user_id: recipient.id,          // CHANGED: from 'userId' to 'user_id'
            transferred_from: user.id,      // CHANGED: from 'transferredFrom' to 'transferred_from'
            transferred_at: new Date().toISOString() // CHANGED: from 'transferredAt' to 'transferred_at'
        })
        .eq('ticket_id', ticketId)  // CHANGED: from 'id' to 'ticket_id'

    if (updateError) {
        console.error("Update failed:", updateError)
        throw new Error('Database update failed')
    }

    console.log("Transfer successful")

    return new Response(JSON.stringify({ 
        success: true, 
        message: `Transferred to ${normalizedEmail}` 
    }), { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
    })

  } catch (error) {
    console.error("Transfer error:", error.message)
    return new Response(JSON.stringify({ 
        success: false, 
        message: error.message 
    }), { 
        status: 400, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
    })
  }
})