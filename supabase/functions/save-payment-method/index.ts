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

    const { paymentMethodId, setAsDefault } = await req.json()
    let { data: profile } = await supabase.from('users').select('stripe_customer_id').eq('id', user.id).single()
    let customerId = profile?.stripe_customer_id

    if (!customerId) {
        const customer = await stripe.customers.create({ email: user.email, metadata: { supabaseUID: user.id } })
        customerId = customer.id
        await supabase.from('users').update({ stripe_customer_id: customerId }).eq('id', user.id)
    }

    await stripe.paymentMethods.attach(paymentMethodId, { customer: customerId })
    if (setAsDefault) {
      await stripe.customers.update(customerId, { invoice_settings: { default_payment_method: paymentMethodId } })
    }

    return new Response(JSON.stringify({ success: true }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})