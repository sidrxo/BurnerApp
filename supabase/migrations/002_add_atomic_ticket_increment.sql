-- Migration: Add atomic ticket increment function
-- Description: Prevents race conditions when multiple users purchase tickets simultaneously
-- Note: Uses UUID for proper Supabase event IDs
-- IMPORTANT: Run convert-event-ids-to-uuid.sql FIRST if you have Firebase-style IDs

-- Drop old TEXT version if it exists (from Firebase migration)
DROP FUNCTION IF EXISTS increment_tickets_sold(TEXT);

-- Create function for atomic ticket increment with UUID
CREATE OR REPLACE FUNCTION increment_tickets_sold(p_event_id UUID)
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
GRANT EXECUTE ON FUNCTION increment_tickets_sold(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION increment_tickets_sold(UUID) TO service_role;
