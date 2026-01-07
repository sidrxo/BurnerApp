# Stripe Webhook Setup for Payment Failure Logging

This webhook automatically logs declined payments to your audit_logs table.

## How It Works

1. User enters declined card in iOS app (e.g., `4000 0000 0000 0002`)
2. Stripe SDK returns error to iOS app
3. **Stripe sends webhook event `payment_intent.payment_failed` to your server**
4. Webhook handler logs the failure to `audit_logs` table
5. View failures in burnerdashboard at `/audit-logs`

---

## Setup Instructions

### Step 1: Deploy the Webhook Function

The webhook function is already in your codebase at:
```
supabase/functions/stripe-webhook/index.ts
```

Deploy it:
```bash
cd /home/user/BurnerApp
supabase functions deploy stripe-webhook
```

### Step 2: Get Your Webhook Endpoint URL

After deployment, your webhook URL will be:
```
https://[your-project-ref].supabase.co/functions/v1/stripe-webhook
```

Example:
```
https://lsqlgyyugysvhvxtssik.supabase.co/functions/v1/stripe-webhook
```

### Step 3: Create Webhook in Stripe Dashboard

1. Go to **Stripe Dashboard** → https://dashboard.stripe.com/webhooks
2. Click **"Add endpoint"**
3. Enter your webhook URL:
   ```
   https://lsqlgyyugysvhvxtssik.supabase.co/functions/v1/stripe-webhook
   ```
4. Select events to listen for:
   - ✅ `payment_intent.payment_failed` (CRITICAL - this logs declined payments)
   - ✅ `payment_intent.canceled` (optional - logs user cancellations)
   - ✅ `payment_intent.succeeded` (optional - backup logging)
5. Click **"Add endpoint"**

### Step 4: Get Webhook Signing Secret

After creating the webhook:
1. Click on your new webhook endpoint
2. Click **"Reveal"** in the "Signing secret" section
3. Copy the secret (starts with `whsec_...`)

### Step 5: Add Secret to Supabase

1. Go to **Supabase Dashboard** → Settings → Edge Functions
2. Add environment variable:
   - Name: `STRIPE_WEBHOOK_SECRET`
   - Value: `whsec_...` (paste your signing secret)
3. Click **"Save"**

### Step 6: Test the Webhook

#### Option A: Test with Stripe CLI (Local Testing)
```bash
# Install Stripe CLI
brew install stripe/stripe-cli/stripe

# Login
stripe login

# Forward webhooks to local function
stripe listen --forward-to http://localhost:54321/functions/v1/stripe-webhook

# In another terminal, trigger test event
stripe trigger payment_intent.payment_failed
```

#### Option B: Test with Real Declined Card (Production)
1. Open your iOS app
2. Try to purchase a ticket with card: `4000 0000 0000 0002` (always declines)
3. Payment will fail
4. Check Supabase SQL Editor:
   ```sql
   SELECT
     event_type,
     event_action,
     user_email,
     error_message,
     error_code,
     amount_cents / 100.0 as amount,
     created_at
   FROM audit_logs
   WHERE event_type = 'payment'
     AND event_action = 'failed'
   ORDER BY created_at DESC
   LIMIT 10;
   ```

---

## Webhook Events Handled

| Event | Description | Logged As |
|-------|-------------|-----------|
| `payment_intent.payment_failed` | Card declined, insufficient funds, expired card, etc. | `event_action: 'failed'` |
| `payment_intent.canceled` | User canceled payment | `event_action: 'cancelled'` |
| `payment_intent.succeeded` | Payment succeeded (backup - already logged in confirm-purchase) | `event_action: 'succeeded'` |

---

## Error Codes You'll See

When viewing audit logs, you'll see these error codes:

| Error Code | Meaning | Test Card |
|------------|---------|-----------|
| `card_declined` | Generic decline | `4000 0000 0000 0002` |
| `insufficient_funds` | Not enough money | `4000 0000 0000 9995` |
| `expired_card` | Card expired | `4000 0000 0000 0069` |
| `incorrect_cvc` | Wrong CVV | `4000 0000 0000 0127` |
| `processing_error` | Stripe processing issue | `4000 0000 0000 0119` |

---

## Verify Webhook is Working

### Check Stripe Dashboard
1. Go to **Stripe Dashboard** → Webhooks
2. Click on your endpoint
3. View **"Recent events"** - should see events being delivered

### Check Supabase Logs
```bash
# View edge function logs
supabase functions logs stripe-webhook --follow
```

Or in Supabase Dashboard → Edge Functions → stripe-webhook → Logs

### Check Audit Logs Table
```sql
-- View all payment failures from last 24 hours
SELECT
  event_action,
  user_email,
  error_message,
  error_code,
  amount_cents / 100.0 as amount_gbp,
  created_at
FROM audit_logs
WHERE event_type = 'payment'
  AND event_action IN ('failed', 'cancelled')
  AND created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;
```

---

## Troubleshooting

**Problem:** Webhook not receiving events
- Check webhook URL is correct (must be HTTPS)
- Verify webhook is enabled in Stripe Dashboard
- Check Stripe Dashboard → Webhooks → Recent events for delivery errors

**Problem:** Getting 401/403 errors
- Ensure `STRIPE_WEBHOOK_SECRET` is set in Supabase
- Verify secret matches Stripe Dashboard signing secret

**Problem:** Events received but not logged
- Check `audit_logs` table exists (run migration 003)
- Check `create_audit_log` function exists
- View edge function logs for errors

**Problem:** `create_audit_log` function not found
- Run the audit logs migration (FILE 2 from earlier)

---

## Security Notes

✅ **Webhook signature verification** - Prevents fake webhook calls
✅ **Service role credentials** - Bypasses RLS for logging
✅ **HTTPS only** - Stripe requires secure endpoints
✅ **Secret environment variable** - Not exposed in code

---

## What Gets Logged

For each declined payment, the audit log contains:

```json
{
  "event_type": "payment",
  "event_action": "failed",
  "user_email": "customer@example.com",
  "user_id": "uuid...",
  "amount_cents": 4999,
  "currency": "gbp",
  "error_code": "card_declined",
  "error_message": "Your card was declined",
  "resource_type": "payment",
  "resource_id": "pi_...",
  "metadata": {
    "payment_intent_id": "pi_...",
    "event_id": "uuid...",
    "event_name": "Love Saves The Day"
  },
  "ip_address": "1.2.3.4",
  "created_at": "2026-01-07T20:30:00Z"
}
```

---

## Next Steps

After setup is complete:
1. ✅ Test with declined card `4000 0000 0000 0002`
2. ✅ Verify logs appear in `/audit-logs` dashboard
3. ✅ Set up alerts for critical payment failures (optional)
4. ✅ Export failure data for analysis (CSV export available in dashboard)
