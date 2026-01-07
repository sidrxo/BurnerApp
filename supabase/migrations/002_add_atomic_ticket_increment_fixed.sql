-- Migration: Add atomic ticket increment function (FIXED for Firebase IDs)
-- Description: Prevents race conditions when multiple users purchase tickets simultaneously
-- Fixed: Changed parameter type from UUID to TEXT to support Firebase-style event IDs

-- Drop old function if it exists
DROP FUNCTION IF EXISTS increment_tickets_sold(UUID);

-- Create function for atomic ticket increment with TEXT parameter
CREATE OR REPLACE FUNCTION increment_tickets_sold(p_event_id TEXT)
RETURNS void AS $$
BEGIN
  UPDATE events
  SET
    tickets_sold = tickets_sold + 1,
    updated_at = NOW()
  WHERE id = p_event_id;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission to authenticated users and service role
GRANT EXECUTE ON FUNCTION increment_tickets_sold(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION increment_tickets_sold(TEXT) TO service_role;
