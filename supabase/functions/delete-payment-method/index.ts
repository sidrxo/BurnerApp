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

    const { paymentMethodId } = await req.json()
    const { data: profile } = await supabase.from('users').select('stripe_customer_id').eq('id', user.id).single()
    
    const paymentMethod = await stripe.paymentMethods.retrieve(paymentMethodId)
    if (paymentMethod.customer !== profile?.stripe_customer_id) throw new Error('Unauthorized')

    await stripe.paymentMethods.detach(paymentMethodId)
    return new Response(JSON.stringify({ success: true }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})