-- Migration: Convert Event IDs from Firebase-style TEXT to UUID
-- Description: Ensures all event IDs are proper UUIDs for Supabase compatibility

-- Check current data type of events.id
DO $$
DECLARE
  current_type text;
BEGIN
  SELECT data_type INTO current_type
  FROM information_schema.columns
  WHERE table_name = 'events'
    AND column_name = 'id'
    AND table_schema = 'public';

  RAISE NOTICE 'Current events.id type: %', current_type;

  -- If it's already uuid, we're good
  IF current_type = 'uuid' THEN
    RAISE NOTICE '✅ Events table already uses UUID - no migration needed';
  ELSE
    RAISE NOTICE '❌ Events table uses % - migration needed', current_type;
    RAISE NOTICE 'Events table must use UUID type for proper Supabase integration';
    RAISE NOTICE 'All existing Firebase-style IDs will need to be converted';
  END IF;
END $$;

-- If you need to convert existing TEXT IDs to UUIDs, run this:
-- (Only run if events.id is currently TEXT type)
/*
-- Step 1: Add a new UUID column
ALTER TABLE events ADD COLUMN id_new UUID DEFAULT gen_random_uuid();

-- Step 2: Update all rows with new UUIDs
UPDATE events SET id_new = gen_random_uuid() WHERE id_new IS NULL;

-- Step 3: Update foreign key references
-- Update tickets table
ALTER TABLE tickets ADD COLUMN event_id_new UUID;
UPDATE tickets t SET event_id_new = e.id_new
FROM events e WHERE t.event_id = e.id;

-- Update bookmarks table
ALTER TABLE bookmarks ADD COLUMN event_id_new UUID;
UPDATE bookmarks b SET event_id_new = e.id_new
FROM events e WHERE b.event_id = e.id;

-- Step 4: Drop old columns and constraints
ALTER TABLE tickets DROP CONSTRAINT IF EXISTS tickets_event_id_fkey;
ALTER TABLE bookmarks DROP CONSTRAINT IF EXISTS bookmarks_event_id_fkey;

ALTER TABLE tickets DROP COLUMN event_id;
ALTER TABLE bookmarks DROP COLUMN event_id;
ALTER TABLE events DROP COLUMN id;

-- Step 5: Rename new columns
ALTER TABLE events RENAME COLUMN id_new TO id;
ALTER TABLE tickets RENAME COLUMN event_id_new TO event_id;
ALTER TABLE bookmarks RENAME COLUMN event_id_new TO event_id;

-- Step 6: Re-add constraints
ALTER TABLE events ADD PRIMARY KEY (id);
ALTER TABLE tickets ADD CONSTRAINT tickets_event_id_fkey
  FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE;
ALTER TABLE bookmarks ADD CONSTRAINT bookmarks_event_id_fkey
  FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE;

RAISE NOTICE '✅ Migration complete - all event IDs are now UUIDs';
*/

-- Note: After running this migration, you'll need to:
-- 1. Update your iOS app to use the new UUIDs when creating events
-- 2. Clear any cached Firebase-style IDs from the app
-- 3. Regenerate any bookmarks or tickets with new event references
