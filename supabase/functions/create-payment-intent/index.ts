import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { corsHeaders } from "../_shared/cors.ts"
import { stripe } from "../_shared/stripe.ts"
import { createAdminClient } from "../_shared/supabase.ts"

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createAdminClient()
    
    // 1. Verify Auth
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) throw new Error('Missing Authorization header')
    
    const { data: { user }, error: authError } = await supabase.auth.getUser(
      authHeader.replace('Bearer ', '')
    )
    
    if (authError || !user) {
      console.error('Auth error:', authError)
      throw new Error('Unauthenticated')
    }

    console.log(`🔐 Creating payment for user: ${user.email} (${user.id})`)

    // 2. Get event ID from request
    const { eventId } = await req.json()
    if (!eventId) throw new Error('Event ID is required')

    console.log(`🎫 Processing payment for event: ${eventId}`)

    // 3. Fetch Event Data
    const { data: event, error: eventError } = await supabase
      .from('events')
      .select('*')
      .eq('id', eventId)
      .single()

    if (eventError || !event) {
      console.error('Event not found:', eventError)
      throw new Error('Event not found')
    }

    // 4. Check if event is sold out
    if (event.tickets_sold >= event.max_tickets) {
      throw new Error('Event is sold out')
    }

    console.log(`💰 Event price: £${event.price}, Tickets sold: ${event.tickets_sold}/${event.max_tickets}`)

    // 5. Handle Stripe Customer (lazy creation)
    let customerId: string
    
    // Try to get existing customer - FIXED: Use try-catch instead of .catch()
    let profile = null
    try {
      const { data, error } = await supabase
        .from('users')
        .select('stripe_customer_id')
        .eq('id', user.id)
        .single()
      
      if (!error) {
        profile = data
      }
    } catch (error) {
      console.log('No existing customer profile found, will create new one')
    }

    if (profile?.stripe_customer_id) {
      customerId = profile.stripe_customer_id
      console.log(`👤 Using existing Stripe customer: ${customerId}`)
    } else {
      // Create new customer
      console.log(`👤 Creating new Stripe customer for: ${user.email}`)
      const customer = await stripe.customers.create({
        email: user.email,
        metadata: { 
          supabaseUID: user.id,
          app: 'burner'
        }
      })
      customerId = customer.id
      
      // Update user in background (fire-and-forget)
      supabase
        .from('users')
        .update({ stripe_customer_id: customerId })
        .eq('id', user.id)
        .then(() => console.log(`✅ Updated user with customer ID: ${customerId}`))
        .catch(err => console.warn('⚠️ Failed to update user customer ID:', err))
    }

    // 6. Create Payment Intent (with rich metadata)
    console.log(`💳 Creating payment intent for £${event.price}`)
    
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(event.price * 100), // Convert to pence/cents
      currency: 'gbp',
      customer: customerId,
      metadata: {
        // Critical for ticket creation later
        eventId: eventId,
        userId: user.id,
        eventName: event.name,
        eventPrice: event.price.toString(),
        venue: event.venue,
        // Additional context
        app: 'burner',
        timestamp: Date.now().toString(),
        version: '1.0'
      },
      automatic_payment_methods: { 
        enabled: true 
      },
      description: `Ticket for ${event.name} at ${event.venue}`,
      statement_descriptor: 'BURNERTICKET*',
      statement_descriptor_suffix: event.name.substring(0, 10)
    })

    console.log(`✅ Payment intent created: ${paymentIntent.id}`)
    console.log(`   Client secret: ${paymentIntent.client_secret?.substring(0, 20)}...`)
    console.log(`   Metadata:`, paymentIntent.metadata)

    // 7. Return response (NO pending_payments table needed!)
    return new Response(
      JSON.stringify({
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
        amount: event.price,
        eventName: event.name,
        currency: 'gbp'
      }),
      { 
        headers: { 
          ...corsHeaders, 
          'Content-Type': 'application/json' 
        } 
      }
    )

  } catch (error) {
    console.error('❌ create-payment-intent error:', error)
    
    // Return user-friendly error messages
    let errorMessage = error.message
    let statusCode = 400
    
    if (error.message.includes('Event is sold out')) {
      errorMessage = 'Sorry, this event is sold out'
    } else if (error.message.includes('Event not found')) {
      errorMessage = 'Event not found'
      statusCode = 404
    } else if (error.message.includes('Unauthenticated')) {
      errorMessage = 'Please sign in to purchase tickets'
      statusCode = 401
    }
    
    return new Response(
      JSON.stringify({ 
        error: errorMessage,
        details: process.env.NODE_ENV === 'development' ? error.message : undefined
      }),
      { 
        status: statusCode, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})