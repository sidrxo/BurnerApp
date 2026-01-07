# Testing Guide: Audit Logs & Failed Transactions

## Prerequisites

1. Ensure migrations are run in Supabase SQL Editor
2. Use Stripe **test mode** (keys starting with `sk_test_` and `pk_test_`)
3. Have admin access to view audit logs in burnerdashboard

---

## Part 1: Testing Audit Logs Table

### Step 1: Run Migration
```sql
-- In Supabase SQL Editor, verify table exists:
SELECT EXISTS (
  SELECT FROM information_schema.tables
  WHERE table_schema = 'public'
  AND table_name = 'audit_logs'
);
```

### Step 2: Insert Test Data
Run the queries in `test-audit-logs.sql` (replace UUIDs with real values from your database)

### Step 3: View Logs in Dashboard
1. Go to `http://localhost:3000/audit-logs` (or your burnerdashboard URL)
2. Login as an admin user (siteAdmin, venueAdmin, or subAdmin)
3. You should see the test logs with filtering/sorting options

### Step 4: Test RLS Policies

**Test admin access:**
```sql
-- Login as admin user in Supabase dashboard, then run:
SELECT * FROM audit_logs ORDER BY created_at DESC LIMIT 5;
-- ✅ Should return logs
```

**Test non-admin access:**
```sql
-- Login as regular customer user, then run:
SELECT * FROM audit_logs ORDER BY created_at DESC LIMIT 5;
-- ❌ Should return 0 rows (RLS blocks access)
```

**Test insert from client (should fail):**
```typescript
// In browser console or iOS app:
const { error } = await supabase.from('audit_logs').insert({
  event_type: 'test',
  event_action: 'test'
});
// ❌ Should fail with permission error (only service role can insert)
```

---

## Part 2: Testing Failed Transactions

### Stripe Test Card Numbers

Use these cards in your iOS app or web checkout:

| Scenario | Card Number | CVV | Expiry | Expected Result |
|----------|-------------|-----|--------|-----------------|
| **Insufficient Funds** | `4000 0000 0000 9995` | Any | Future | Payment fails, logs `insufficient_funds` |
| **Card Declined** | `4000 0000 0000 0002` | Any | Future | Payment fails, logs `card_declined` |
| **Expired Card** | `4000 0000 0000 0069` | Any | Future | Payment fails, logs `expired_card` |
| **Incorrect CVC** | `4000 0000 0000 0127` | Any | Future | Payment fails, logs `incorrect_cvc` |
| **Processing Error** | `4000 0000 0000 0119` | Any | Future | Payment fails, logs `processing_error` |
| **Requires Auth (3DS)** | `4000 0025 0000 3155` | Any | Future | Requires authentication |
| **Success** | `4242 4242 4242 4242` | Any | Future | Payment succeeds (control test) |

### Test Scenarios

#### Test 1: Insufficient Funds
```
1. Open iOS app or burnerdashboard checkout
2. Select an event and click "Buy Ticket"
3. Enter card: 4000 0000 0000 9995
4. Complete payment
5. Check audit logs - should see entry:
   - event_type: payment
   - event_action: failed
   - status: failure
   - error_code: insufficient_funds
   - amount_cents: [ticket price]
```

#### Test 2: Rate Limiting
```
1. Make 6 purchase attempts within 1 minute from same user
2. 6th attempt should be blocked
3. Check audit logs - should see entry:
   - event_type: security
   - event_action: rate_limit_exceeded
   - status: failure
   - severity: warning
   - error_message: "Rate limit exceeded: 5 requests per minute"
```

#### Test 3: Sold Out Event
```
1. Create an event with max_capacity = 1
2. Buy 1 ticket successfully (sold_out = true)
3. Try to buy another ticket
4. Check audit logs - should see:
   - event_type: payment
   - event_action: failed
   - error_message: "Event is sold out"
```

#### Test 4: Network/System Errors
```
1. Stop Supabase service or simulate network error
2. Try to complete purchase
3. Check audit logs when service restored - should see:
   - event_type: payment
   - event_action: failed
   - severity: error
   - error_message: [network/system error details]
```

#### Test 5: Successful Payment + Refund
```
1. Complete successful purchase with card 4242 4242 4242 4242
2. Check audit logs - should see:
   - event_action: succeeded
   - status: success
3. Process refund via Stripe dashboard or API
4. Check audit logs - should see new entry:
   - event_action: refunded
   - status: success
```

---

## Part 3: Verification Checklist

### In Supabase SQL Editor:
```sql
-- View all payment failures in last 24 hours
SELECT
  event_type,
  event_action,
  user_email,
  amount_cents / 100.0 as amount_dollars,
  error_message,
  error_code,
  created_at
FROM audit_logs
WHERE event_type = 'payment'
  AND status = 'failure'
  AND created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;

-- Count events by type
SELECT
  event_type,
  event_action,
  status,
  COUNT(*) as count
FROM audit_logs
GROUP BY event_type, event_action, status
ORDER BY count DESC;

-- View rate limit violations
SELECT
  user_email,
  ip_address,
  metadata->>'endpoint' as endpoint,
  created_at
FROM audit_logs
WHERE event_action = 'rate_limit_exceeded'
ORDER BY created_at DESC;
```

### In Burnerdashboard:
- [ ] Can view audit logs at `/audit-logs`
- [ ] Can filter by event type (payment, ticket, security, system)
- [ ] Can filter by severity (info, warning, error, critical)
- [ ] Can filter by status (success, failure, pending)
- [ ] Can search by user email or error message
- [ ] Can export to CSV
- [ ] Statistics cards show correct counts
- [ ] Pagination works (50 logs per page)

### Expected Audit Log Entries:
After testing, you should see logs for:
- ✅ Successful payments (event_action: succeeded)
- ✅ Failed payments with error codes (event_action: failed)
- ✅ Rate limit violations (event_action: rate_limit_exceeded)
- ✅ Refunds (event_action: refunded)
- ✅ Ticket scans (event_action: scanned)
- ✅ Duplicate scan attempts (event_action: scan_failed)

---

## Part 4: Production Testing Checklist

Before deploying to production:

- [ ] Verify `STRIPE_SECRET_KEY` is production key (`sk_live_...`)
- [ ] Verify `SUPABASE_URL` uses HTTPS
- [ ] Test rate limiting with real traffic patterns
- [ ] Verify audit logs capture all payment failures
- [ ] Test RLS policies with different user roles
- [ ] Verify CSV export works with large datasets (1000+ logs)
- [ ] Set up alerts for critical severity logs
- [ ] Verify 7-year retention (set up cleanup job if needed)

---

## Quick Test Script

Run this from iOS app or browser console after importing Supabase client:

```typescript
// Test 1: Try to view audit logs as regular user (should fail)
const { data, error } = await supabase
  .from('audit_logs')
  .select('*')
  .limit(5);

console.log('Regular user access:', error ? 'BLOCKED ✅' : 'ALLOWED ❌');

// Test 2: Try to insert as regular user (should fail)
const { error: insertError } = await supabase
  .from('audit_logs')
  .insert({
    event_type: 'test',
    event_action: 'test',
    status: 'success'
  });

console.log('Regular user insert:', insertError ? 'BLOCKED ✅' : 'ALLOWED ❌');
```

---

## Troubleshooting

**Problem:** Can't see audit logs in dashboard
- Check if you're logged in as admin (role: siteAdmin/venueAdmin/subAdmin)
- Check browser console for RLS errors
- Verify migration was run successfully

**Problem:** Failed payments not logging
- Check if `audit.ts` is imported in edge functions
- Check Supabase edge function logs for errors
- Verify SERVICE_ROLE_KEY is set correctly

**Problem:** All users can see audit logs
- Check RLS is enabled: `SELECT * FROM pg_tables WHERE tablename = 'audit_logs';`
- Verify policies exist: `SELECT * FROM pg_policies WHERE tablename = 'audit_logs';`

**Problem:** Edge functions can't insert logs
- Verify edge functions use service role client
- Check SERVICE_ROLE_KEY environment variable
- Check for TypeScript errors in audit.ts
