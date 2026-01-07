-- Test Audit Logs
-- Run this in Supabase SQL Editor to create test data

-- Test 1: Successful payment
SELECT create_audit_log(
  'payment'::event_type_enum,
  'succeeded'::event_action_enum,
  'success'::status_enum,
  'info'::severity_enum,
  'user'::uuid,  -- Replace with actual user ID
  'test@example.com',
  'customer',
  'ticket',
  'event-123'::uuid,  -- Replace with actual event ID
  '127.0.0.1',
  'Mozilla/5.0 Test',
  jsonb_build_object(
    'payment_intent_id', 'pi_test_success',
    'ticket_id', 'TKT1234'
  ),
  4999,  -- $49.99 in cents
  'usd',
  NULL,
  NULL
);

-- Test 2: Failed payment (insufficient funds)
SELECT create_audit_log(
  'payment'::event_type_enum,
  'failed'::event_action_enum,
  'failure'::status_enum,
  'warning'::severity_enum,
  'user'::uuid,  -- Replace with actual user ID
  'test@example.com',
  'customer',
  'ticket',
  'event-123'::uuid,
  '127.0.0.1',
  'Mozilla/5.0 Test',
  jsonb_build_object(
    'payment_intent_id', 'pi_test_insufficient_funds'
  ),
  4999,
  'usd',
  'Payment failed: Insufficient funds',
  'insufficient_funds'
);

-- Test 3: Rate limit exceeded
SELECT create_audit_log(
  'security'::event_type_enum,
  'rate_limit_exceeded'::event_action_enum,
  'failure'::status_enum,
  'warning'::severity_enum,
  'user'::uuid,  -- Replace with actual user ID
  'test@example.com',
  'customer',
  NULL,
  NULL,
  '127.0.0.1',
  'Mozilla/5.0 Test',
  jsonb_build_object(
    'endpoint', '/confirm-purchase',
    'limit', 5,
    'window_ms', 60000
  ),
  NULL,
  NULL,
  'Rate limit exceeded: 5 requests per minute',
  'rate_limit_exceeded'
);

-- Test 4: Successful refund
SELECT create_audit_log(
  'payment'::event_type_enum,
  'refunded'::event_action_enum,
  'success'::status_enum,
  'info'::severity_enum,
  'user'::uuid,  -- Replace with actual user ID
  'test@example.com',
  'customer',
  'ticket',
  'event-123'::uuid,
  '127.0.0.1',
  'Mozilla/5.0 Test',
  jsonb_build_object(
    'payment_intent_id', 'pi_test_refund',
    'ticket_id', 'TKT1234',
    'refund_id', 're_test_123',
    'reason', 'Customer requested'
  ),
  4999,
  'usd',
  NULL,
  NULL
);

-- Test 5: Duplicate ticket scan attempt
SELECT create_audit_log(
  'ticket'::event_type_enum,
  'scan_failed'::event_action_enum,
  'failure'::status_enum,
  'warning'::severity_enum,
  'user'::uuid,  -- Replace with actual user ID (scanner)
  'scanner@venue.com',
  'venueAdmin',
  'ticket',
  'ticket-456'::uuid,  -- Replace with actual ticket ID
  '127.0.0.1',
  'BurnerApp iOS/1.0',
  jsonb_build_object(
    'ticket_number', 'TKT1234',
    'event_id', 'event-123'
  ),
  NULL,
  NULL,
  'Ticket already scanned',
  'already_used'
);

-- Query to view all test logs
SELECT
  id,
  event_type,
  event_action,
  status,
  severity,
  user_email,
  resource_type,
  amount_cents,
  error_message,
  created_at
FROM audit_logs
ORDER BY created_at DESC
LIMIT 10;

-- Get stats
SELECT * FROM get_audit_log_stats();
