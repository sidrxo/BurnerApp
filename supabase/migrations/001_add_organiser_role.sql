-- Migration: Add Event Organiser Role and Venue Assignments
-- Description: Adds support for event organisers who can create events at multiple assigned venues

-- 1. Update users table role constraint to include 'organiser'
-- Note: The users table already exists with a role field
-- This adds 'organiser' as a valid role option
-- Run this in Supabase SQL Editor:
ALTER TABLE users
DROP CONSTRAINT IF EXISTS users_role_check;

ALTER TABLE users
ADD CONSTRAINT users_role_check
CHECK (role IN ('siteAdmin', 'venueAdmin', 'subAdmin', 'scanner', 'organiser', 'user'));

-- 2. Create organizer_venues junction table
-- This manages the many-to-many relationship between organisers and venues
CREATE TABLE IF NOT EXISTS organizer_venues (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organizer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  venue_id UUID NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES users(id),
  UNIQUE(organizer_id, venue_id)
);

-- 3. Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_organizer_venues_organizer_id ON organizer_venues(organizer_id);
CREATE INDEX IF NOT EXISTS idx_organizer_venues_venue_id ON organizer_venues(venue_id);

-- 4. Enable Row Level Security
ALTER TABLE organizer_venues ENABLE ROW LEVEL SECURITY;

-- 5. Create RLS policies for organizer_venues table

-- Allow admins to view all organizer-venue assignments
CREATE POLICY "Admins can view all organizer venues"
ON organizer_venues FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.active = true
  )
);

-- Only siteAdmins can insert organizer-venue assignments
CREATE POLICY "Only siteAdmins can create organizer venue assignments"
ON organizer_venues FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role = 'siteAdmin'
    AND users.active = true
  )
);

-- Only siteAdmins can delete organizer-venue assignments
CREATE POLICY "Only siteAdmins can delete organizer venue assignments"
ON organizer_venues FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role = 'siteAdmin'
    AND users.active = true
  )
);

-- 6. Create helper function to get organizer's venues
CREATE OR REPLACE FUNCTION get_organizer_venues(organizer_uuid UUID)
RETURNS TABLE (
  venue_id UUID,
  venue_name TEXT,
  venue_city TEXT,
  venue_address TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    v.id,
    v.name,
    v.city,
    v.address
  FROM venues v
  INNER JOIN organizer_venues ov ON v.id = ov.venue_id
  WHERE ov.organizer_id = organizer_uuid
  AND v.active = true
  ORDER BY v.name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Create helper function to check if organizer has access to venue
CREATE OR REPLACE FUNCTION organizer_has_venue_access(organizer_uuid UUID, venue_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM organizer_venues
    WHERE organizer_id = organizer_uuid
    AND venue_id = venue_uuid
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Update events table policies to allow organisers to create events at their venues
-- Note: This assumes the events table already has RLS enabled
-- Drop existing insert policy if needed and recreate

DROP POLICY IF EXISTS "Admins can insert events" ON events;
DROP POLICY IF EXISTS "Admins can create events" ON events;

CREATE POLICY "Admins can create events"
ON events FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users a
    WHERE a.id = auth.uid()
    AND a.active = true
    AND (
      -- siteAdmin can create events anywhere
      a.role = 'siteAdmin'
      OR
      -- venueAdmin/subAdmin can create at their venue
      (a.role IN ('venueAdmin', 'subAdmin') AND a.venue_id = events.venue_id)
      OR
      -- organiser can create at their assigned venues
      (a.role = 'organiser' AND organizer_has_venue_access(a.id, events.venue_id))
    )
  )
);

-- Update events update policy to allow organisers to update their events
DROP POLICY IF EXISTS "Admins can update events" ON events;

CREATE POLICY "Admins can update events"
ON events FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users a
    WHERE a.id = auth.uid()
    AND a.active = true
    AND (
      -- siteAdmin can update any event
      a.role = 'siteAdmin'
      OR
      -- venueAdmin/subAdmin can update events at their venue
      (a.role IN ('venueAdmin', 'subAdmin') AND a.venue_id = events.venue_id)
      OR
      -- organiser can update events at their assigned venues
      (a.role = 'organiser' AND organizer_has_venue_access(a.id, events.venue_id))
    )
  )
);

-- Update events delete policy to allow organisers to delete their events
DROP POLICY IF EXISTS "Admins can delete events" ON events;

CREATE POLICY "Admins can delete events"
ON events FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users a
    WHERE a.id = auth.uid()
    AND a.active = true
    AND (
      -- siteAdmin can delete any event
      a.role = 'siteAdmin'
      OR
      -- venueAdmin/subAdmin can delete events at their venue
      (a.role IN ('venueAdmin', 'subAdmin') AND a.venue_id = events.venue_id)
      OR
      -- organiser can delete events at their assigned venues
      (a.role = 'organiser' AND organizer_has_venue_access(a.id, events.venue_id))
    )
  )
);

-- Migration complete
-- Run this SQL in your Supabase SQL Editor to apply the changes
