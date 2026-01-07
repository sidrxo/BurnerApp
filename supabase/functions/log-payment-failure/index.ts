import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { corsHeaders } from "../_shared/cors.ts"
import { createAdminClient } from "../_shared/supabase.ts"
import { logPaymentEvent } from "../_shared/audit.ts"

/**
 * Log Payment Failure Endpoint
 *
 * Called by iOS app when Stripe payment fails on the client side.
 * This is an alternative to Stripe webhooks for logging declined payments.
 *
 * Usage from iOS:
 *   POST /log-payment-failure
 *   Headers: Authorization: Bearer <user-token>
 *   Body: {
 *     paymentIntentId: "pi_...",
 *     eventId: "uuid...",
 *     amount: 49.99,
 *     errorCode: "card_declined",
 *     errorMessage: "Your card was declined"
 *   }
 */

serve(async (req) => {
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
      return new Response(
        JSON.stringify({ error: 'Missing Authorization header' }),
        { status: 401, headers }
      )
    }

    const { data: { user }, error: authError } = await supabase.auth.getUser(
      authHeader.replace('Bearer ', '')
    )

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthenticated' }),
        { status: 401, headers }
      )
    }

    // 2. Parse request body
    const {
      paymentIntentId,
      eventId,
      amount,
      errorCode,
      errorMessage
    } = await req.json()

    if (!paymentIntentId) {
      return new Response(
        JSON.stringify({ error: 'paymentIntentId is required' }),
        { status: 400, headers }
      )
    }

    console.log(`📝 Logging payment failure for ${user.email}`)
    console.log(`   Payment Intent: ${paymentIntentId}`)
    console.log(`   Error: ${errorCode} - ${errorMessage}`)

    // 3. Log to audit_logs
    await logPaymentEvent(supabase, req, 'failed', {
      userId: user.id,
      userEmail: user.email || 'unknown',
      paymentIntentId,
      eventId,
      amountCents: Math.round((amount || 0) * 100),
      status: 'failure',
      errorMessage: errorMessage || 'Payment failed',
      errorCode: errorCode || 'unknown'
    })

    console.log(`✅ Payment failure logged to audit_logs`)

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Payment failure logged'
      }),
      { headers }
    )

  } catch (error) {
    console.error('❌ log-payment-failure error:', error)

    return new Response(
      JSON.stringify({
        error: 'Failed to log payment failure',
        details: error.message
      }),
      {
        status: 500,
        headers
      }
    )
  }
})
