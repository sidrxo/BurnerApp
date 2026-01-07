import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { corsHeaders } from "../_shared/cors.ts"
import { stripe } from "../_shared/stripe.ts"
import { createAdminClient } from "../_shared/supabase.ts"
import { checkRateLimit, createRateLimitResponse, getRequestIdentifier, RATE_LIMITS } from "../_shared/ratelimit.ts"

serve(async (req) => {
  // Set CORS headers for all responses
  const headers = {
    ...corsHeaders,
    'Content-Type': 'application/json'
  }

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers })
  }

  try {
    const supabase = createAdminClient()
    
    // 1. Verify Auth
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      console.error('❌ Missing Authorization header')
      return new Response(
        JSON.stringify({ 
          success: false, 
          message: 'Missing Authorization header' 
        }), 
        { 
          status: 401, 
          headers 
        }
      )
    }
    
    const { data: { user }, error: authError } = await supabase.auth.getUser(
      authHeader.replace('Bearer ', '')
    )
    
    if (authError || !user) {
      console.error('Auth error:', authError)
      return new Response(
        JSON.stringify({ 
          success: false, 
          message: 'Unauthenticated' 
        }), 
        { 
          status: 401, 
          headers 
        }
      )
    }

    console.log(`🔐 Confirm purchase for user: ${user.email} (${user.id})`)

    // 2. Rate limiting (5 requests per minute for payments)
    const rateLimitIdentifier = getRequestIdentifier(req, user.id)
    const rateLimitResult = checkRateLimit(rateLimitIdentifier, RATE_LIMITS.PAYMENT)

    if (!rateLimitResult.success) {
      console.warn(`⚠️ Rate limit exceeded for ${user.email}`)
      return createRateLimitResponse(rateLimitResult, headers)
    }

    // 3. Parse request body with better error handling
    let requestBody
    let paymentIntentId
    
    try {
      const text = await req.text()
      console.log(`📥 Raw request body: ${text}`)
      
      if (!text || text.trim() === '') {
        throw new Error('Empty request body')
      }
      
      requestBody = JSON.parse(text)
      paymentIntentId = requestBody.paymentIntentId || requestBody.payment_intent_id
      
      console.log(`📋 Parsed paymentIntentId: ${paymentIntentId}`)
      console.log(`📦 Full request body:`, JSON.stringify(requestBody, null, 2))
      
    } catch (parseError) {
      console.error('❌ Failed to parse request body:', parseError)
      return new Response(
        JSON.stringify({ 
          success: false, 
          message: 'Invalid request body format' 
        }), 
        { 
          status: 400, 
          headers 
        }
      )
    }
    
    if (!paymentIntentId) {
      console.error('❌ Payment Intent ID is required')
      console.error('❌ Received request body:', requestBody)
      return new Response(
        JSON.stringify({ 
          success: false, 
          message: 'Payment Intent ID is required' 
        }), 
        { 
          status: 400, 
          headers 
        }
      )
    }

    console.log(`💰 Processing payment intent: ${paymentIntentId}`)

    // 3. Verify Stripe Status & Get Metadata
    console.log(`🔍 Retrieving payment intent from Stripe...`)
    let paymentIntent
    try {
      paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId)
    } catch (stripeError) {
      console.error('❌ Stripe retrieval error:', stripeError)
      return new Response(
        JSON.stringify({ 
          success: false, 
          message: `Invalid payment intent: ${stripeError.message}` 
        }), 
        { 
          status: 400, 
          headers 
        }
      )
    }
    
    console.log(`📊 Payment intent status: ${paymentIntent.status}`)
    console.log(`💳 Amount: ${paymentIntent.amount / 100} ${paymentIntent.currency}`)
    
    if (paymentIntent.status !== 'succeeded') {
      console.error(`❌ Payment not succeeded. Status: ${paymentIntent.status}`)
      return new Response(
        JSON.stringify({ 
          success: false, 
          message: `Payment not succeeded: ${paymentIntent.status}` 
        }), 
        { 
          status: 400, 
          headers 
        }
      )
    }

    console.log('✅ Payment succeeded in Stripe')
    console.log('📋 Payment intent metadata:', JSON.stringify(paymentIntent.metadata, null, 2))

    // 4. Get data from Stripe metadata
    const eventId = paymentIntent.metadata.eventId
    const userId = paymentIntent.metadata.userId
    const eventName = paymentIntent.metadata.eventName || 'Unknown Event'
    
    if (!eventId || !userId) {
      console.error('❌ Missing metadata in payment intent:', { eventId, userId })
      return new Response(
        JSON.stringify({ 
          success: false, 
          message: 'Invalid payment intent: missing event or user data in metadata' 
        }), 
        { 
          status: 400, 
          headers 
        }
      )
    }

    // Verify user matches
    if (userId !== user.id) {
      console.error(`❌ User mismatch. Payment user: ${userId}, Request user: ${user.id}`)
      return new Response(
        JSON.stringify({ 
          success: false, 
          message: 'User mismatch - unauthorized' 
        }), 
        { 
          status: 403, 
          headers 
        }
      )
    }

    console.log(`🎫 Creating ticket for event: ${eventId} (${eventName})`)

    // 5. Check if ticket already exists (idempotency)
    const { data: existingTicket, error: existingError } = await supabase
      .from('tickets')
      .select('ticket_id, ticket_number')
      .eq('payment_intent_id', paymentIntentId)
      .maybeSingle()

    if (existingError) {
      console.warn('⚠️ Error checking existing ticket:', existingError)
    }
    
    if (existingTicket) {
      console.log(`✅ Ticket already exists: ${existingTicket.ticket_number} (${existingTicket.ticket_id})`)
      return new Response(
        JSON.stringify({ 
          success: true, 
          ticketId: existingTicket.ticket_id,
          ticketNumber: existingTicket.ticket_number,
          message: 'Ticket already created' 
        }), 
        { headers }
      )
    }

    // 6. Get event details
    const { data: event, error: eventError } = await supabase
      .from('events')
      .select('*')
      .eq('id', eventId)
      .single()

    if (eventError || !event) {
      console.error('❌ Event not found:', eventError)
      
      // Attempt refund
      try {
        const refund = await stripe.refunds.create({ 
          payment_intent: paymentIntentId, 
          reason: 'requested_by_customer' 
        })
        console.log('✅ Refund issued due to event not found:', refund.id)
      } catch (refundError) {
        console.warn('⚠️ Failed to issue refund:', refundError)
      }
      
      return new Response(
        JSON.stringify({ 
          success: false, 
          message: 'Event not found - refund issued' 
        }), 
        { 
          status: 404, 
          headers 
        }
      )
    }

    // 7. Check if event is sold out
    if (event.tickets_sold >= event.max_tickets) {
      console.error(`❌ Event sold out: ${event.tickets_sold}/${event.max_tickets}`)
      
      // Attempt refund
      try {
        const refund = await stripe.refunds.create({ 
          payment_intent: paymentIntentId, 
          reason: 'requested_by_customer' 
        })
        console.log('✅ Refund issued due to event sold out:', refund.id)
      } catch (refundError) {
        console.warn('⚠️ Failed to issue refund:', refundError)
      }
      
      return new Response(
        JSON.stringify({ 
          success: false, 
          message: 'Event is sold out - refund issued' 
        }), 
        { 
          status: 400, 
          headers 
        }
      )
    }

    // 8. Generate ticket number using cryptographically secure random
    const randomBytes = crypto.getRandomValues(new Uint8Array(3))
    const ticketNumber = `TKT${Array.from(randomBytes).map(b => b.toString(36).toUpperCase()).join('').slice(0, 4).padEnd(4, '0')}`
    const ticketId = crypto.randomUUID()
    
    console.log(`🎟️ Generating ticket: ${ticketNumber} (${ticketId})`)

    // 9. Create ticket directly
    const { data: ticket, error: insertError } = await supabase
      .from('tickets')
      .insert({
        ticket_id: ticketId,
        event_id: eventId,
        user_id: user.id,
        ticket_number: ticketNumber,
        event_name: event.name,
        venue: event.venue,
        start_time: event.start_time,
        total_price: event.price,
        purchase_date: new Date().toISOString(),
        status: 'confirmed',
        payment_intent_id: paymentIntentId,
        venue_id: event.venue_id || null,
        qr_code: JSON.stringify({
          type: 'EVENT_TICKET',
          ticket_id: ticketId,
          event_id: eventId,
          user_id: user.id,
          ticket_number: ticketNumber,
          timestamp: Date.now(),
          version: '1.0'
        })
      })
      .select('ticket_id, ticket_number')
      .single()

    if (insertError) {
      console.error('❌ Ticket creation failed:', insertError)
      
      // Attempt refund
      try {
        const refund = await stripe.refunds.create({ 
          payment_intent: paymentIntentId, 
          reason: 'requested_by_customer' 
        })
        console.log('✅ Refund issued due to ticket creation failure:', refund.id)
      } catch (refundError) {
        console.warn('⚠️ Failed to issue refund:', refundError)
      }
      
      return new Response(
        JSON.stringify({ 
          success: false, 
          message: `Failed to create ticket: ${insertError.message} - refund issued` 
        }), 
        { 
          status: 500, 
          headers 
        }
      )
    }

    // 10. Update tickets sold count atomically using database increment
    const { error: updateError } = await supabase.rpc('increment_tickets_sold', {
      p_event_id: eventId
    })

    if (updateError) {
      console.warn('⚠️ Failed to update tickets sold count:', updateError)
    } else {
      console.log(`📈 Tickets sold count incremented for event ${eventId}`)
    }

    console.log(`✅ Ticket created: ${ticket.ticket_number} (${ticket.ticket_id})`)

    // 11. Return success
    return new Response(
      JSON.stringify({ 
        success: true, 
        ticketId: ticket.ticket_id,
        ticketNumber: ticket.ticket_number,
        message: 'Ticket created successfully'
      }), 
      { headers }
    )

  } catch (error) {
    console.error('❌ Confirm Purchase Error:', error)
    
    return new Response(
      JSON.stringify({ 
        success: false, 
        message: error.message || 'Internal server error'
      }), 
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})