import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { stripe } from "../_shared/stripe.ts"
import { createAdminClient } from "../_shared/supabase.ts"
import { logPaymentEvent } from "../_shared/audit.ts"

// Get webhook secret from environment
const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET')

serve(async (req) => {
  const signature = req.headers.get('stripe-signature')

  if (!signature) {
    console.error('❌ Missing stripe-signature header')
    return new Response('Webhook signature missing', { status: 400 })
  }

  if (!webhookSecret) {
    console.error('❌ STRIPE_WEBHOOK_SECRET not configured')
    return new Response('Webhook not configured', { status: 500 })
  }

  try {
    const body = await req.text()
    const supabase = createAdminClient()

    // Verify webhook signature - CHANGED: use constructEventAsync
    let event
    try {
      event = await stripe.webhooks.constructEventAsync(
        body,
        signature,
        webhookSecret
      )
    } catch (err) {
      console.error('❌ Webhook signature verification failed:', err.message)
      return new Response('Webhook signature verification failed', { status: 400 })
    }

    console.log(`🔨 Stripe webhook received: ${event.type}`)

    // Handle payment_intent.payment_failed event
    if (event.type === 'payment_intent.payment_failed') {
      const paymentIntent = event.data.object

      console.log(`❌ Payment failed: ${paymentIntent.id}`)
      console.log(`   Last error: ${paymentIntent.last_payment_error?.code}`)
      console.log(`   Message: ${paymentIntent.last_payment_error?.message}`)

      const metadata = paymentIntent.metadata
      const lastError = paymentIntent.last_payment_error

      // Log failed payment to audit logs
      await logPaymentEvent(supabase, req, 'failed', {
        userId: metadata.userId || 'unknown',
        userEmail: paymentIntent.receipt_email || metadata.userEmail || 'unknown',
        paymentIntentId: paymentIntent.id,
        eventId: metadata.eventId,
        amountCents: paymentIntent.amount,
        status: 'failure',
        errorMessage: lastError?.message || 'Payment failed',
        errorCode: lastError?.code || 'unknown'
      })

      console.log(`✅ Failed payment logged to audit_logs`)
    }

    // Handle payment_intent.succeeded event (optional - for completeness)
    else if (event.type === 'payment_intent.succeeded') {
      const paymentIntent = event.data.object
      console.log(`✅ Payment succeeded via webhook: ${paymentIntent.id}`)
      // Note: We already log this in confirm-purchase, so this is redundant
      // but useful for catching edge cases where confirm-purchase isn't called
    }

    // Handle payment_intent.canceled event
    else if (event.type === 'payment_intent.canceled') {
      const paymentIntent = event.data.object
      const metadata = paymentIntent.metadata

      await logPaymentEvent(supabase, req, 'cancelled', {
        userId: metadata.userId || 'unknown',
        userEmail: paymentIntent.receipt_email || 'unknown',
        paymentIntentId: paymentIntent.id,
        eventId: metadata.eventId,
        amountCents: paymentIntent.amount,
        status: 'failure',
        errorMessage: 'Payment canceled by user',
        errorCode: 'canceled'
      })

      console.log(`✅ Canceled payment logged to audit_logs`)
    }

    return new Response(JSON.stringify({ received: true }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (error) {
    console.error('❌ Webhook handler error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      }
    )
  }
})