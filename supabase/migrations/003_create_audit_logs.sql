-- Migration: Create Audit Logs System
-- Description: Comprehensive audit logging for payments, tickets, admin actions, and security events

-- 1. Create audit_logs table
CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Timestamp (indexed for fast queries)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,

  -- Event classification
  event_type TEXT NOT NULL, -- 'payment', 'ticket', 'admin', 'auth', 'security'
  event_action TEXT NOT NULL, -- 'initiated', 'succeeded', 'failed', 'scanned', 'created', 'updated', 'deleted'
  severity TEXT NOT NULL DEFAULT 'INFO', -- 'INFO', 'WARN', 'ERROR', 'CRITICAL'

  -- User context
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  user_email TEXT,
  user_role TEXT,

  -- Resource identification
  resource_type TEXT, -- 'event', 'ticket', 'venue', 'user', 'payment'
  resource_id TEXT, -- Can be UUID or other identifier

  -- Action details
  action_description TEXT NOT NULL,
  status TEXT, -- 'success', 'failure', 'pending'

  -- Request context
  ip_address TEXT,
  user_agent TEXT,

  -- Additional context (flexible JSON storage)
  metadata JSONB DEFAULT '{}',

  -- Error details (for failures)
  error_message TEXT,
  error_code TEXT,

  -- Financial tracking (for payment events)
  amount_cents INTEGER,
  currency TEXT DEFAULT 'usd',

  CONSTRAINT severity_check CHECK (severity IN ('INFO', 'WARN', 'ERROR', 'CRITICAL'))
);

-- 2. Create indexes for fast queries
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_audit_logs_event_type ON audit_logs(event_type);
CREATE INDEX idx_audit_logs_severity ON audit_logs(severity);
CREATE INDEX idx_audit_logs_resource ON audit_logs(resource_type, resource_id);
CREATE INDEX idx_audit_logs_status ON audit_logs(status) WHERE status IS NOT NULL;

-- Composite index for common dashboard queries
CREATE INDEX idx_audit_logs_dashboard ON audit_logs(event_type, created_at DESC, severity);

-- GIN index for JSONB metadata searches
CREATE INDEX idx_audit_logs_metadata ON audit_logs USING GIN (metadata);

-- 3. Enable Row Level Security
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies

-- All authenticated admins can view audit logs
CREATE POLICY "Admins can view all audit logs"
ON audit_logs FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role IN ('siteAdmin', 'venueAdmin', 'subAdmin')
    AND users.active = true
  )
);

-- Only system (service role) can insert audit logs
-- This prevents tampering from client apps
CREATE POLICY "Service role can insert audit logs"
ON audit_logs FOR INSERT
TO service_role
WITH CHECK (true);

-- Audit logs are append-only: NO UPDATE OR DELETE policies
-- This ensures data integrity and compliance

-- 5. Create helper function for inserting audit logs
CREATE OR REPLACE FUNCTION create_audit_log(
  p_event_type TEXT,
  p_event_action TEXT,
  p_action_description TEXT,
  p_severity TEXT DEFAULT 'INFO',
  p_user_id UUID DEFAULT NULL,
  p_user_email TEXT DEFAULT NULL,
  p_user_role TEXT DEFAULT NULL,
  p_resource_type TEXT DEFAULT NULL,
  p_resource_id TEXT DEFAULT NULL,
  p_status TEXT DEFAULT NULL,
  p_ip_address TEXT DEFAULT NULL,
  p_user_agent TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}',
  p_error_message TEXT DEFAULT NULL,
  p_error_code TEXT DEFAULT NULL,
  p_amount_cents INTEGER DEFAULT NULL,
  p_currency TEXT DEFAULT 'usd'
) RETURNS UUID AS $$
DECLARE
  v_log_id UUID;
BEGIN
  INSERT INTO audit_logs (
    event_type,
    event_action,
    action_description,
    severity,
    user_id,
    user_email,
    user_role,
    resource_type,
    resource_id,
    status,
    ip_address,
    user_agent,
    metadata,
    error_message,
    error_code,
    amount_cents,
    currency
  ) VALUES (
    p_event_type,
    p_event_action,
    p_action_description,
    p_severity,
    p_user_id,
    p_user_email,
    p_user_role,
    p_resource_type,
    p_resource_id,
    p_status,
    p_ip_address,
    p_user_agent,
    p_metadata,
    p_error_message,
    p_error_code,
    p_amount_cents,
    p_currency
  ) RETURNING id INTO v_log_id;

  RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute to service role only
GRANT EXECUTE ON FUNCTION create_audit_log TO service_role;

-- 6. Create view for dashboard with enriched data
CREATE OR REPLACE VIEW audit_logs_enriched AS
SELECT
  al.*,
  u.email as current_user_email,
  u.role as current_user_role
FROM audit_logs al
LEFT JOIN users u ON al.user_id = u.id
ORDER BY al.created_at DESC;

-- Grant select on view to authenticated users
GRANT SELECT ON audit_logs_enriched TO authenticated;

-- 7. Create function to get audit log summary statistics
CREATE OR REPLACE FUNCTION get_audit_log_stats(
  p_start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() - INTERVAL '30 days',
  p_end_date TIMESTAMP WITH TIME ZONE DEFAULT NOW()
) RETURNS TABLE (
  event_type TEXT,
  total_count BIGINT,
  success_count BIGINT,
  failure_count BIGINT,
  critical_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    al.event_type,
    COUNT(*) as total_count,
    COUNT(*) FILTER (WHERE al.status = 'success') as success_count,
    COUNT(*) FILTER (WHERE al.status = 'failure') as failure_count,
    COUNT(*) FILTER (WHERE al.severity = 'CRITICAL') as critical_count
  FROM audit_logs al
  WHERE al.created_at BETWEEN p_start_date AND p_end_date
  GROUP BY al.event_type
  ORDER BY total_count DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_audit_log_stats TO authenticated;

-- 8. Create automatic cleanup function for old logs (optional - run via cron)
-- Note: Consider legal/compliance retention requirements before enabling
CREATE OR REPLACE FUNCTION cleanup_old_audit_logs(
  p_retention_days INTEGER DEFAULT 2555 -- ~7 years for financial compliance
) RETURNS INTEGER AS $$
DECLARE
  v_deleted_count INTEGER;
BEGIN
  DELETE FROM audit_logs
  WHERE created_at < NOW() - (p_retention_days || ' days')::INTERVAL
  AND severity NOT IN ('ERROR', 'CRITICAL'); -- Keep errors forever

  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION cleanup_old_audit_logs TO service_role;

-- Migration complete
-- Audit logging system ready for production use
