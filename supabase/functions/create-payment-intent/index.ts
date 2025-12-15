import { serve } from "std/http/server.ts"
import { corsHeaders } from "../_shared/cors.ts"
import { stripe } from "../_shared/stripe.ts"
import { createAdminClient } from "../_shared/supabase.ts"

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const supabase = createAdminClient()
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) throw new Error('Missing Authorization header')
    const { data: { user }, error: authError } = await supabase.auth.getUser(authHeader.replace('Bearer ', ''))
    if (authError || !user) throw new Error('Unauthenticated')
    
    const { eventId } = await req.json()
    if (!eventId) throw new Error('Event ID is required')

    const [eventResult, userProfileResult] = await Promise.all([
      supabase.from('events').select('*').eq('id', eventId).single(),
      supabase.from('users').select('stripe_customer_id, email').eq('id', user.id).single()
    ])

    if (eventResult.error) throw new Error('Event not found')
    const event = eventResult.data

    let customerId = userProfileResult.data?.stripe_customer_id
    if (!customerId) {
      const customer = await stripe.customers.create({
        email: user.email,
        metadata: { supabaseUID: user.id }
      })
      customerId = customer.id
      supabase.from('users').update({ stripe_customer_id: customerId }).eq('id', user.id)
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(event.price * 100),
      currency: 'gbp',
      customer: customerId,
      metadata: { eventId, userId: user.id, eventName: event.name },
      automatic_payment_methods: { enabled: true },
    })

    await supabase.from('pending_payments').insert({
      id: paymentIntent.id,
      user_id: user.id,
      event_id: eventId,
      amount: event.price,
      status: 'pending',
      metadata: { eventName: event.name }
    })

    return new Response(JSON.stringify({
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
        amount: event.price
      }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})