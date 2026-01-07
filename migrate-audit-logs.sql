-- Migration: Upgrade Audit Logs Schema
-- This preserves your existing audit_logs data and creates the new schema

-- Step 1: Rename existing audit_logs table to preserve old data
ALTER TABLE IF EXISTS audit_logs RENAME TO audit_logs_old;

-- Step 2: Now run the new audit logs migration
-- Copy the entire contents of supabase/migrations/003_create_audit_logs.sql here
-- OR run it as a separate migration after this step

-- Step 3: (Optional) Migrate old data to new schema
-- Uncomment and customize this if you want to preserve old audit log data

/*
INSERT INTO audit_logs (
  event_type,
  event_action,
  action_description,
  resource_type,
  resource_id,
  user_id,
  metadata,
  created_at
)
SELECT
  COALESCE(old.resource, 'unknown') as event_type,
  COALESCE(old.action, 'unknown') as event_action,
  CONCAT('Legacy: ', old.action, ' on ', old.resource) as action_description,
  old.resource as resource_type,
  old.resource_id,
  -- Convert text user_id to UUID (only if valid UUID format)
  CASE
    WHEN old.user_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    THEN old.user_id::UUID
    ELSE NULL
  END as user_id,
  COALESCE(old.details, '{}'::jsonb) as metadata,
  old.created_at
FROM audit_logs_old old;
*/

-- Step 4: Verify migration
SELECT
  'Old table row count' as info,
  COUNT(*) as count
FROM audit_logs_old
UNION ALL
SELECT
  'New table row count' as info,
  COUNT(*) as count
FROM audit_logs;

-- Step 5: (Optional) After verifying, drop old table
-- DROP TABLE audit_logs_old;
