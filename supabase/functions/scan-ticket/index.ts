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
    
    if (!user) {
      console.error('Authentication failed: No user found')
      throw new Error('Unauthenticated')
    }

    console.log(`🔐 Authenticated user: ${user.email} (${user.id})`)

    // Accept only necessary parameters
    const { ticket_id, ticket_number, event_id } = await req.json()
    
    if (!ticket_id && !(ticket_number && event_id)) {
      throw new Error('Invalid parameters: Need ticket_id OR (ticket_number + event_id)')
    }

    console.log(`📋 Scan attempt - Ticket ID: ${ticket_id}, Ticket Number: ${ticket_number}, Event: ${event_id}`)

    let query = supabase
      .from('tickets')
      .select('*, events!inner(*)')  // Changed: Join with events to get venue_id
      .limit(1)
    
    if (ticket_id) {
      // UUID lookup (from QR code)
      query = query.eq('ticket_id', ticket_id)
    } else {
      // Ticket number lookup (manual entry with event context)
      query = query.eq('ticket_number', ticket_number)
               .eq('event_id', event_id)
    }
    
    const { data: tickets, error: ticketError } = await query

    if (ticketError || !tickets || tickets.length === 0) {
      console.error('Ticket lookup failed:', ticketError)
      throw new Error('Ticket not found')
    }

    const ticket = tickets[0]
    const eventVenueId = ticket.events?.venue_id
    
    console.log(`🎫 Found ticket: ${ticket.ticket_number} for event "${ticket.events?.name}" at venue: ${eventVenueId}`)

    // 🔐 CRITICAL: Verify scanner permission with venue check
    try {
      const scanner = await verifyScannerPermission(supabase, user.id, eventVenueId)
      console.log(`✅ Permission granted: ${user.email} (${scanner.role})`)
    } catch (permError) {
      console.error('❌ Permission denied:', permError.message)
      throw permError // Re-throw the permission error
    }

    // Check ticket status
    if (ticket.status === 'used') {
      console.log(`🚫 Ticket already used, scanned by: ${ticket.scanned_by}`)
      
      // Try to get scanner details for the already-used message
      let scannerDetails = { email: 'Unknown', role: 'Unknown' }
      if (ticket.scanned_by) {
        const { data: scanner } = await supabase
          .from('admins')
          .select('email, role')
          .eq('id', ticket.scanned_by)
          .single()
          .catch(() => null) // Gracefully handle missing scanner
        
        if (scanner) scannerDetails = scanner
      }

      return new Response(JSON.stringify({
        success: false,
        message: "Ticket already used",
        ticketStatus: "used",
        scannedBy: scannerDetails.email,
        scannedByEmail: scannerDetails.email,
        scannedAt: ticket.used_at,
        ticketNumber: ticket.ticket_number,
        userName: "Guest" // You might want to fetch from users table
      }), { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      })
    }

    if (ticket.status === 'cancelled') {
      console.log('❌ Ticket cancelled')
      return new Response(JSON.stringify({ 
        success: false, 
        message: "Ticket cancelled" 
      }), { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      })
    }

    if (ticket.status !== 'confirmed') {
      console.log(`❌ Invalid ticket status: ${ticket.status}`)
      throw new Error(`Invalid ticket status: ${ticket.status}`)
    }

    // ✅ Update ticket to used
    const { error: updateError } = await supabase
      .from('tickets')
      .update({
        status: 'used',
        used_at: new Date().toISOString(),
        scanned_by: user.id,
        scanned_by_email: user.email
      })
      .eq('ticket_id', ticket.ticket_id)

    if (updateError) {
      console.error('Failed to update ticket:', updateError)
      throw new Error('Failed to update ticket status')
    }

    console.log(`✅ Ticket ${ticket.ticket_number} successfully scanned by ${user.email}`)

    return new Response(JSON.stringify({
      success: true,
      message: "Ticket validated successfully",
      ticket: {
        id: ticket.ticket_id,
        ticket_number: ticket.ticket_number,
        status: "used",
        scannedAt: new Date().toISOString(),
        scannedBy: user.email,
        scannedByRole: ticket.scanned_by_role, // Optional: you could store this
        userName: "Guest",
        eventName: ticket.events?.name
      }
    }), { 
      headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
    })

  } catch (error) {
    console.error('❌ Scan error:', error.message)
    
    // Return more helpful error messages
    let errorMessage = error.message
    let statusCode = 400
    
    if (error.message.includes('Permission denied')) {
      statusCode = 403 // Forbidden
    } else if (error.message.includes('Unauthenticated')) {
      statusCode = 401 // Unauthorized
    }
    
    return new Response(JSON.stringify({ 
      success: false, 
      message: errorMessage 
    }), { 
      status: statusCode,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
    })
  }
})