import { serve } from "std/http/server.ts"
import { corsHeaders } from "../_shared/cors.ts"
import { stripe } from "../_shared/stripe.ts"
import { createAdminClient } from "../_shared/supabase.ts"

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const supabase = createAdminClient()
    const authHeader = req.headers.get('Authorization')
    const { data: { user } } = await supabase.auth.getUser(authHeader?.replace('Bearer ', '') ?? '')
    if (!user) throw new Error('Unauthenticated')

    const { paymentIntentId } = await req.json()
    
    // 1. Verify Stripe Status
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId)
    if (paymentIntent.status !== 'succeeded') throw new Error(`Payment not succeeded: ${paymentIntent.status}`)

    // 2. Verify Pending Payment
    const { data: pendingPayment } = await supabase.from('pending_payments').select('*').eq('id', paymentIntentId).single()
    
    if (!pendingPayment) throw new Error('Payment record not found')
    if (pendingPayment.status === 'completed') throw new Error('Ticket already created')

    // 3. Mint Ticket (Atomic RPC)
    const { data: ticketResult, error: ticketError } = await supabase.rpc('mint_ticket', {
      p_event_id: pendingPayment.event_id,
      p_user_id: user.id,
      p_payment_intent_id: paymentIntentId,
      p_payment_method: paymentIntent.payment_method ? { id: paymentIntent.payment_method, type: 'card' } : {}
    })

    // --- NEW LOGIC CHECK START ---
    
    // Check for System Error (e.g., function missing)
    if (ticketError) {
      console.error("RPC System Error:", ticketError)
      await stripe.refunds.create({ payment_intent: paymentIntentId, reason: 'requested_by_customer' })
      throw new Error(ticketError.message)
    }

    // Check for Logic Error (e.g., "Sold Out" or "Event Not Found")
    // The RPC returns { success: boolean, message: string }
    if (ticketResult && ticketResult.success === false) {
      console.error("RPC Logic Error:", ticketResult.message)
      await stripe.refunds.create({ payment_intent: paymentIntentId, reason: 'requested_by_customer' })
      throw new Error(ticketResult.message || "Failed to mint ticket")
    }
    
    // --- NEW LOGIC CHECK END ---

    // 4. Cleanup
    await supabase.from('pending_payments').delete().eq('id', paymentIntentId)

    return new Response(JSON.stringify({ success: true, ticketId: ticketResult.ticketId }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })

  } catch (error) {
    console.error("Confirm Purchase Error:", error)
    return new Response(JSON.stringify({ success: false, message: error.message }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})