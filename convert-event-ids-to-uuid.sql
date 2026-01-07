-- ============================================
-- CONVERT EVENT IDS FROM FIREBASE TO UUID
-- ============================================
-- This migration converts all event IDs from Firebase-style TEXT to proper UUIDs
-- Ticket numbers (TKT6v0E) remain short - they're separate from event IDs

-- STEP 1: Create mapping table to preserve relationships
CREATE TABLE event_id_mapping (
  old_id TEXT PRIMARY KEY,
  new_id UUID DEFAULT gen_random_uuid(),
  event_name TEXT
);

-- Insert all current events into mapping
INSERT INTO event_id_mapping (old_id, event_name)
SELECT id, name FROM events;

-- Verify mapping created
SELECT
  COUNT(*) as total_events,
  COUNT(DISTINCT old_id) as unique_old_ids,
  COUNT(DISTINCT new_id) as unique_new_ids
FROM event_id_mapping;

-- Show sample mapping
SELECT old_id, new_id, event_name FROM event_id_mapping LIMIT 5;

-- ============================================
-- STEP 2: Update events table
-- ============================================

-- Add new UUID column
ALTER TABLE events ADD COLUMN id_new UUID;

-- Populate with mapped UUIDs
UPDATE events e
SET id_new = m.new_id
FROM event_id_mapping m
WHERE e.id = m.old_id;

-- Verify all events have new IDs
SELECT
  COUNT(*) as total,
  COUNT(id_new) as with_new_id,
  COUNT(*) - COUNT(id_new) as missing_new_id
FROM events;

-- ============================================
-- STEP 3: Update tickets table
-- ============================================

-- Add new column
ALTER TABLE tickets ADD COLUMN event_id_new UUID;

-- Update with mapped UUIDs
UPDATE tickets t
SET event_id_new = m.new_id
FROM event_id_mapping m
WHERE t.event_id = m.old_id;

-- Verify
SELECT
  COUNT(*) as total_tickets,
  COUNT(event_id_new) as with_new_event_id,
  COUNT(*) - COUNT(event_id_new) as orphaned_tickets
FROM tickets;

-- ============================================
-- STEP 4: Update bookmarks table
-- ============================================

-- Add new column
ALTER TABLE bookmarks ADD COLUMN event_id_new UUID;

-- Update with mapped UUIDs
UPDATE bookmarks b
SET event_id_new = m.new_id
FROM event_id_mapping m
WHERE b.event_id = m.old_id;

-- Verify
SELECT
  COUNT(*) as total_bookmarks,
  COUNT(event_id_new) as with_new_event_id,
  COUNT(*) - COUNT(event_id_new) as orphaned_bookmarks
FROM bookmarks;

-- ============================================
-- STEP 5: Drop old columns and constraints
-- ============================================

-- Drop foreign key constraints
ALTER TABLE tickets DROP CONSTRAINT IF EXISTS tickets_event_id_fkey;
ALTER TABLE bookmarks DROP CONSTRAINT IF EXISTS bookmarks_event_id_fkey;

-- Drop old primary key
ALTER TABLE events DROP CONSTRAINT IF EXISTS events_pkey;

-- Drop old columns
ALTER TABLE events DROP COLUMN id;
ALTER TABLE tickets DROP COLUMN event_id;
ALTER TABLE bookmarks DROP COLUMN event_id;

-- ============================================
-- STEP 6: Rename new columns to final names
-- ============================================

ALTER TABLE events RENAME COLUMN id_new TO id;
ALTER TABLE tickets RENAME COLUMN event_id_new TO event_id;
ALTER TABLE bookmarks RENAME COLUMN event_id_new TO event_id;

-- ============================================
-- STEP 7: Re-create constraints
-- ============================================

-- Add primary key to events
ALTER TABLE events ADD PRIMARY KEY (id);

-- Add foreign keys
ALTER TABLE tickets
  ADD CONSTRAINT tickets_event_id_fkey
  FOREIGN KEY (event_id)
  REFERENCES events(id)
  ON DELETE CASCADE;

ALTER TABLE bookmarks
  ADD CONSTRAINT bookmarks_event_id_fkey
  FOREIGN KEY (event_id)
  REFERENCES events(id)
  ON DELETE CASCADE;

-- Add NOT NULL constraints
ALTER TABLE events ALTER COLUMN id SET NOT NULL;
ALTER TABLE tickets ALTER COLUMN event_id SET NOT NULL;
ALTER TABLE bookmarks ALTER COLUMN event_id SET NOT NULL;

-- ============================================
-- STEP 8: Update increment_tickets_sold to use UUID
-- ============================================

-- Drop TEXT version
DROP FUNCTION IF EXISTS increment_tickets_sold(TEXT);

-- Create UUID version
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

GRANT EXECUTE ON FUNCTION increment_tickets_sold(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION increment_tickets_sold(UUID) TO service_role;

-- ============================================
-- STEP 9: Final verification
-- ============================================

-- Check event IDs are now UUIDs
SELECT
  id,
  name,
  CASE
    WHEN id::text ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      THEN '✅ UUID format'
    ELSE '❌ NOT UUID'
  END as id_format
FROM events
LIMIT 5;

-- Verify foreign key relationships
SELECT
  'Events' as table_name,
  COUNT(*) as count
FROM events
UNION ALL
SELECT
  'Tickets' as table_name,
  COUNT(*) as count
FROM tickets
UNION ALL
SELECT
  'Bookmarks' as table_name,
  COUNT(*) as count
FROM bookmarks
UNION ALL
SELECT
  'Orphaned tickets' as table_name,
  COUNT(*) as count
FROM tickets t
LEFT JOIN events e ON t.event_id = e.id
WHERE e.id IS NULL
UNION ALL
SELECT
  'Orphaned bookmarks' as table_name,
  COUNT(*) as count
FROM bookmarks b
LEFT JOIN events e ON b.event_id = e.id
WHERE e.id IS NULL;

-- Check data types
SELECT
  table_name,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name IN ('events', 'tickets', 'bookmarks')
  AND column_name IN ('id', 'event_id')
ORDER BY table_name, column_name;

-- Export mapping for reference (keep this for 30 days)
SELECT
  old_id as firebase_id,
  new_id as uuid,
  event_name
FROM event_id_mapping
ORDER BY event_name;

-- ============================================
-- CLEANUP (run after verifying everything works)
-- ============================================

-- Drop mapping table (ONLY after verifying app works)
-- DROP TABLE event_id_mapping;

-- ============================================
-- MIGRATION COMPLETE
-- ============================================
-- ✅ Event IDs are now proper UUIDs
-- ✅ Ticket numbers remain short (TKT6v0E format - separate field)
-- ✅ All foreign key relationships preserved
-- ✅ increment_tickets_sold function updated
