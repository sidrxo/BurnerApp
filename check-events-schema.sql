-- Check current events table schema and data
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'events'
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check sample event IDs to see format
SELECT
  id,
  name,
  LENGTH(id::text) as id_length,
  CASE
    WHEN id::text ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN 'UUID'
    ELSE 'Firebase-style'
  END as id_format
FROM events
LIMIT 5;
