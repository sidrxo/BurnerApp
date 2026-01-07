import { useState, useEffect } from "react";
import { supabase } from "@/lib/supabase";

export interface AuditLog {
  id: string;
  created_at: string;
  event_type: 'payment' | 'ticket' | 'admin' | 'auth' | 'security';
  event_action: string;
  severity: 'INFO' | 'WARN' | 'ERROR' | 'CRITICAL';
  user_id?: string;
  user_email?: string;
  user_role?: string;
  resource_type?: string;
  resource_id?: string;
  action_description: string;
  status?: 'success' | 'failure' | 'pending';
  ip_address?: string;
  metadata?: Record<string, any>;
  error_message?: string;
  error_code?: string;
  amount_cents?: number;
  currency?: string;
}

export interface AuditLogStats {
  event_type: string;
  total_count: number;
  success_count: number;
  failure_count: number;
  critical_count: number;
}

export interface AuditLogFilters {
  eventType?: string;
  severity?: string;
  status?: string;
  startDate?: string;
  endDate?: string;
  searchQuery?: string;
}

export function useAuditLogs(filters: AuditLogFilters = {}) {
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [stats, setStats] = useState<AuditLogStats[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [pagination, setPagination] = useState({ page: 1, limit: 50 });
  const [totalCount, setTotalCount] = useState(0);

  useEffect(() => {
    fetchAuditLogs();
    fetchStats();
  }, [filters, pagination.page]);

  const fetchAuditLogs = async () => {
    try {
      setLoading(true);
      setError(null);

      let query = supabase
        .from('audit_logs')
        .select('*', { count: 'exact' })
        .order('created_at', { ascending: false })
        .range(
          (pagination.page - 1) * pagination.limit,
          pagination.page * pagination.limit - 1
        );

      // Apply filters
      if (filters.eventType) {
        query = query.eq('event_type', filters.eventType);
      }
      if (filters.severity) {
        query = query.eq('severity', filters.severity);
      }
      if (filters.status) {
        query = query.eq('status', filters.status);
      }
      if (filters.startDate) {
        query = query.gte('created_at', filters.startDate);
      }
      if (filters.endDate) {
        query = query.lte('created_at', filters.endDate);
      }
      if (filters.searchQuery) {
        query = query.or(`user_email.ilike.%${filters.searchQuery}%,action_description.ilike.%${filters.searchQuery}%,resource_id.ilike.%${filters.searchQuery}%`);
      }

      const { data, error: fetchError, count } = await query;

      if (fetchError) throw fetchError;

      setLogs(data || []);
      setTotalCount(count || 0);
    } catch (err: any) {
      console.error('Error fetching audit logs:', err);
      setError(err.message || 'Failed to fetch audit logs');
    } finally {
      setLoading(false);
    }
  };

  const fetchStats = async () => {
    try {
      // Get stats for the filtered date range
      const startDate = filters.startDate || new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
      const endDate = filters.endDate || new Date().toISOString();

      const { data, error: statsError } = await supabase.rpc('get_audit_log_stats', {
        p_start_date: startDate,
        p_end_date: endDate
      });

      if (statsError) throw statsError;

      setStats(data || []);
    } catch (err: any) {
      console.error('Error fetching stats:', err);
    }
  };

  const nextPage = () => {
    setPagination(prev => ({ ...prev, page: prev.page + 1 }));
  };

  const prevPage = () => {
    setPagination(prev => ({ ...prev, page: Math.max(1, prev.page - 1) }));
  };

  const setPage = (page: number) => {
    setPagination(prev => ({ ...prev, page }));
  };

  const totalPages = Math.ceil(totalCount / pagination.limit);

  return {
    logs,
    stats,
    loading,
    error,
    pagination: { ...pagination, totalPages, totalCount },
    nextPage,
    prevPage,
    setPage,
    refresh: fetchAuditLogs
  };
}
