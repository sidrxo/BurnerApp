import Stripe from "https://esm.sh/stripe@14.19.0"

// Validate Stripe API key
const stripeSecretKey = Deno.env.get('STRIPE_SECRET_KEY')

if (!stripeSecretKey) {
  throw new Error('STRIPE_SECRET_KEY environment variable is required')
}

// Production validation: ensure using live keys in production
const isProduction = Deno.env.get('DENO_DEPLOYMENT_ID') !== undefined
if (isProduction && stripeSecretKey.startsWith('sk_test_')) {
  console.warn('⚠️ WARNING: Using Stripe test key in production environment')
}

export const stripe = new Stripe(stripeSecretKey, {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
})