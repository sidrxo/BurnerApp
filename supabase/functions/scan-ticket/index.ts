import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { corsHeaders } from "../_shared/cors.ts"
import { createAdminClient } from "../_shared/supabase.ts"
import { verifyScannerPermission } from "../_shared/permissions.ts"
import { checkRateLimit, createRateLimitResponse, getRequestIdentifier, RATE_LIMITS } from "../_shared/ratelimit.ts"

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const supabase = createAdminClient()
    const authHeader = req.headers.get('Authorization')
    const { data: { user } } = await supabase.auth.getUser(authHeader?.replace('Bearer ', '') ?? '')
    
    if (!user) {
      console.error('Authentication failed: No user found')
      return new Response(JSON.stringify({ 
        success: false, 
        message: "Please sign in to scan tickets",
        errorType: "UNAUTHENTICATED"
      }), { 
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      })
    }

    console.log(`🔐 Authenticated user: ${user.email} (${user.id})`)

    // Rate limiting (30 requests per minute for ticket scanning)
    const rateLimitIdentifier = getRequestIdentifier(req, user.id)
    const rateLimitResult = checkRateLimit(rateLimitIdentifier, RATE_LIMITS.TICKET_SCAN)

    if (!rateLimitResult.success) {
      console.warn(`⚠️ Rate limit exceeded for ${user.email}`)
      return createRateLimitResponse(rateLimitResult, { ...corsHeaders, 'Content-Type': 'application/json' })
    }

    const { ticket_id, ticket_number, event_id } = await req.json()
    
    if (!ticket_id && !(ticket_number && event_id)) {
      return new Response(JSON.stringify({ 
        success: false, 
        message: "Invalid ticket format. Please try again.",
        errorType: "INVALID_PARAMETERS"
      }), { 
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      })
    }

    console.log(`📋 Scan attempt - Ticket ID: ${ticket_id}, Ticket Number: ${ticket_number}, Event: ${event_id}`)

    // Build the query
    let query = supabase
      .from('tickets')
      .select('*, events(*)')
      .limit(1)
    
    if (ticket_id) {
      query = query.eq('ticket_id', ticket_id)
      console.log(`🔍 Searching by ticket_id: ${ticket_id}`)
    } else {
      query = query.eq('ticket_number', ticket_number)
               .eq('event_id', event_id)
      console.log(`🔍 Searching by ticket_number: ${ticket_number}, event_id: ${event_id}`)
    }
    
    const { data: tickets, error: ticketError } = await query

    console.log(`🔍 Query result - Found tickets: ${tickets?.length || 0}`)
    if (ticketError) console.error('🔍 Query error:', ticketError)

    if (ticketError || !tickets || tickets.length === 0) {
      return new Response(JSON.stringify({ 
        success: false, 
        message: "Ticket not found. Please check and try again.",
        errorType: "TICKET_NOT_FOUND"
      }), { 
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      })
    }

    const ticket = tickets[0]
    const eventVenueId = ticket.events?.venue_id
    
    console.log(`🎫 Found ticket: ${ticket.ticket_number} for event "${ticket.events?.name}" at venue: ${eventVenueId}`)

    // 🔐 Verify scanner permission with venue check
    try {
      const scanner = await verifyScannerPermission(supabase, user.id, eventVenueId)
      console.log(`✅ Permission granted: ${user.email} (${scanner.role})`)
    } catch (permError) {
      console.error('❌ Permission denied:', permError.message)
      return new Response(JSON.stringify({ 
        success: false, 
        message: "You don't have permission to scan tickets at this venue.",
        errorType: "PERMISSION_DENIED"
      }), { 
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      })
    }

    // Check if ticket is for the correct event (for manual entry)
    if (event_id && ticket.event_id !== event_id) {
      return new Response(JSON.stringify({ 
        success: false, 
        message: "This ticket is for a different event.",
        errorType: "WRONG_EVENT",
        actualEvent: ticket.events?.name
      }), { 
        status: 200, // Use 200 for business logic errors
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      })
    }

    // Check ticket status - ALREADY USED
    if (ticket.status === 'used') {
      console.log(`🚫 Ticket already used, scanned by: ${ticket.scanned_by}`)
      
      // Get scanner details
      let scannerDetails = { email: 'Unknown', role: 'Unknown' }
      if (ticket.scanned_by) {
        try {
          const { data: scanner, error: scannerError } = await supabase
            .from('admins')
            .select('email, role')
            .eq('id', ticket.scanned_by)
            .single()
          
          if (!scannerError && scanner) {
            scannerDetails = scanner
          }
        } catch (e) {
          // Silently fail - just use default "Unknown"
          console.log('Could not fetch scanner details:', e)
        }
      }

      // Return 200 with detailed info about already-used ticket
      return new Response(JSON.stringify({
        success: false,
        message: "This ticket has already been scanned.",
        errorType: "ALREADY_USED",
        ticketNumber: ticket.ticket_number,
        userName: "Guest",
        eventName: ticket.events?.name,
        scannedBy: scannerDetails.email,
        scannedByEmail: scannerDetails.email,
        scannedAt: ticket.used_at
      }), { 
        status: 200, // Use 200 for business logic responses
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      })
    }

    // Check ticket status - CANCELLED
    if (ticket.status === 'cancelled') {
      console.log('❌ Ticket cancelled')
      return new Response(JSON.stringify({ 
        success: false, 
        message: "This ticket has been cancelled.",
        errorType: "CANCELLED"
      }), { 
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      })
    }

    // Check ticket status - OTHER
    if (ticket.status !== 'confirmed') {
      console.log(`❌ Invalid ticket status: ${ticket.status}`)
      return new Response(JSON.stringify({ 
        success: false, 
        message: `Invalid ticket status: ${ticket.status}`,
        errorType: "INVALID_STATUS"
      }), { 
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      })
    }

    // ✅ All checks passed - Update ticket to used
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
      return new Response(JSON.stringify({ 
        success: false, 
        message: "Failed to update ticket. Please try again.",
        errorType: "UPDATE_FAILED"
      }), { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      })
    }

    console.log(`✅ Ticket ${ticket.ticket_number} successfully scanned by ${user.email}`)

    // ✅ SUCCESS
    return new Response(JSON.stringify({
      success: true,
      message: "Ticket validated successfully",
      ticket: {
        id: ticket.ticket_id,
        ticketNumber: ticket.ticket_number,
        status: "used",
        scannedAt: new Date().toISOString(),
        scannedBy: user.email,
        userName: "Guest",
        eventName: ticket.events?.name
      }
    }), { 
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
    })

  } catch (error) {
    console.error('❌ Unexpected error:', error.message)
    
    return new Response(JSON.stringify({ 
      success: false, 
      message: "An unexpected error occurred. Please try again.",
      errorType: "UNKNOWN_ERROR"
    }), { 
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
    })
  }
})