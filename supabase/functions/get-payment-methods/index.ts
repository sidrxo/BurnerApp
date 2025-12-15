import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
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

    const { data: profile } = await supabase.from('users').select('stripe_customer_id').eq('id', user.id).single()
    if (!profile?.stripe_customer_id) return new Response(JSON.stringify({ paymentMethods: [] }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })

    const methods = await stripe.paymentMethods.list({ customer: profile.stripe_customer_id, type: 'card' })
    const customer = await stripe.customers.retrieve(profile.stripe_customer_id) as any

    const formatted = methods.data.map(pm => ({
      id: pm.id,
      brand: pm.card?.brand,
      last4: pm.card?.last4,
      expMonth: pm.card?.exp_month,
      expYear: pm.card?.exp_year,
      isDefault: customer.invoice_settings.default_payment_method === pm.id
    }))

    return new Response(JSON.stringify({ paymentMethods: formatted }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})