#!/bin/bash

# Test Failed Payment Edge Function
# This script simulates various payment failure scenarios

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Testing Failed Payment Scenarios"
echo "=========================================="
echo ""

# Check if SUPABASE_URL and SUPABASE_ANON_KEY are set
if [ -z "$SUPABASE_URL" ]; then
  echo -e "${RED}Error: SUPABASE_URL environment variable not set${NC}"
  echo "Set it with: export SUPABASE_URL='your-url'"
  exit 1
fi

if [ -z "$SUPABASE_ANON_KEY" ]; then
  echo -e "${RED}Error: SUPABASE_ANON_KEY environment variable not set${NC}"
  echo "Set it with: export SUPABASE_ANON_KEY='your-key'"
  exit 1
fi

# Get auth token (replace with actual login)
echo "Step 1: Get authentication token"
echo -e "${YELLOW}You need to replace USER_AUTH_TOKEN with a real token${NC}"
echo "Get it from: supabase.auth.getSession() or login endpoint"
echo ""

USER_AUTH_TOKEN="your-token-here"

# Test data
EVENT_ID="your-event-id-here"  # Replace with real event ID
PAYMENT_METHOD_ID="pm_card_chargeDeclined"  # Stripe test payment method

echo "Step 2: Test insufficient funds (card 4000000000009995)"
echo "----------------------------------------"

curl -X POST "$SUPABASE_URL/functions/v1/confirm-purchase" \
  -H "Authorization: Bearer $USER_AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "eventId": "'$EVENT_ID'",
    "paymentMethodId": "pm_card_chargeDeclinedInsufficientFunds"
  }' \
  --silent \
  | jq '.'

echo ""
echo -e "${GREEN}✓ Check audit logs for 'insufficient_funds' error${NC}"
echo ""

echo "Step 3: Test rate limiting (make 6 requests)"
echo "----------------------------------------"

for i in {1..6}; do
  echo "Request $i..."
  RESPONSE=$(curl -X POST "$SUPABASE_URL/functions/v1/confirm-purchase" \
    -H "Authorization: Bearer $USER_AUTH_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "eventId": "'$EVENT_ID'",
      "paymentMethodId": "pm_card_visa"
    }' \
    --silent \
    --write-out "\n%{http_code}")

  HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

  if [ "$HTTP_CODE" = "429" ]; then
    echo -e "${GREEN}✓ Rate limit triggered on request $i${NC}"
    break
  fi

  sleep 1
done

echo ""
echo -e "${GREEN}✓ Check audit logs for 'rate_limit_exceeded'${NC}"
echo ""

echo "Step 4: View audit logs in Supabase SQL Editor"
echo "----------------------------------------"
echo "Run this query:"
echo ""
echo "SELECT"
echo "  event_type,"
echo "  event_action,"
echo "  status,"
echo "  user_email,"
echo "  error_message,"
echo "  error_code,"
echo "  created_at"
echo "FROM audit_logs"
echo "WHERE created_at > NOW() - INTERVAL '5 minutes'"
echo "ORDER BY created_at DESC;"
echo ""

echo "=========================================="
echo "Testing Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Check Supabase SQL Editor for audit log entries"
echo "2. Check burnerdashboard at /audit-logs"
echo "3. Use Stripe test cards in iOS app for real testing"
echo ""
echo "Stripe test cards:"
echo "  Insufficient funds: 4000 0000 0000 9995"
echo "  Card declined:      4000 0000 0000 0002"
echo "  Expired card:       4000 0000 0000 0069"
echo "  Success:            4242 4242 4242 4242"
echo ""
