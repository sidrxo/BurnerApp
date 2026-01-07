-- Migration: Add atomic ticket increment function
-- Description: Prevents race conditions when multiple users purchase tickets simultaneously

-- Create function for atomic ticket increment
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

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION increment_tickets_sold(UUID) TO authenticated;
