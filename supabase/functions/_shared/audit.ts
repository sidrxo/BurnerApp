/**
 * Audit Logging Utility for Edge Functions
 *
 * Best Practices:
 * - All critical operations should be logged
 * - Logs are append-only (cannot be modified or deleted)
 * - Include enough context for debugging and compliance
 * - Don't log sensitive data (passwords, full credit cards, etc.)
 */

import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.38.1"

export type EventType = 'payment' | 'ticket' | 'admin' | 'auth' | 'security'
export type EventAction =
  | 'initiated' | 'succeeded' | 'failed' | 'refunded'
  | 'scanned' | 'transferred' | 'cancelled'
  | 'created' | 'updated' | 'deleted'
  | 'login' | 'logout' | 'permission_denied' | 'rate_limited'
export type Severity = 'INFO' | 'WARN' | 'ERROR' | 'CRITICAL'
export type Status = 'success' | 'failure' | 'pending'

export interface AuditLogData {
  // Required fields
  eventType: EventType
  eventAction: EventAction
  actionDescription: string

  // Optional context
  severity?: Severity
  userId?: string
  userEmail?: string
  userRole?: string
  resourceType?: string
  resourceId?: string
  status?: Status
  ipAddress?: string
  userAgent?: string
  metadata?: Record<string, any>
  errorMessage?: string
  errorCode?: string
  amountCents?: number
  currency?: string
}

/**
 * Create an audit log entry
 * Uses the admin/service role client to bypass RLS
 */
export async function createAuditLog(
  supabase: SupabaseClient,
  data: AuditLogData
): Promise<string | null> {
  try {
    const { data: result, error } = await supabase.rpc('create_audit_log', {
      p_event_type: data.eventType,
      p_event_action: data.eventAction,
      p_action_description: data.actionDescription,
      p_severity: data.severity || 'INFO',
      p_user_id: data.userId || null,
      p_user_email: data.userEmail || null,
      p_user_role: data.userRole || null,
      p_resource_type: data.resourceType || null,
      p_resource_id: data.resourceId || null,
      p_status: data.status || null,
      p_ip_address: data.ipAddress || null,
      p_user_agent: data.userAgent || null,
      p_metadata: data.metadata || {},
      p_error_message: data.errorMessage || null,
      p_error_code: data.errorCode || null,
      p_amount_cents: data.amountCents || null,
      p_currency: data.currency || 'usd'
    })

    if (error) {
      console.error('Failed to create audit log:', error)
      return null
    }

    return result as string
  } catch (error) {
    console.error('Audit log exception:', error)
    return null
  }
}

/**
 * Extract IP address from request headers
 */
export function getIpAddress(req: Request): string {
  return req.headers.get('x-forwarded-for')?.split(',')[0].trim() ||
         req.headers.get('x-real-ip') ||
         'unknown'
}

/**
 * Get user agent from request
 */
export function getUserAgent(req: Request): string {
  return req.headers.get('user-agent')?.substring(0, 255) || 'unknown'
}

/**
 * Helper: Log payment event
 */
export async function logPaymentEvent(
  supabase: SupabaseClient,
  req: Request,
  action: EventAction,
  data: {
    userId: string
    userEmail: string
    paymentIntentId: string
    eventId?: string
    ticketId?: string
    amountCents: number
    status: Status
    errorMessage?: string
    errorCode?: string
  }
): Promise<void> {
  await createAuditLog(supabase, {
    eventType: 'payment',
    eventAction: action,
    actionDescription: `Payment ${action} for ${data.amountCents / 100} USD`,
    severity: data.status === 'failure' ? 'ERROR' : 'INFO',
    userId: data.userId,
    userEmail: data.userEmail,
    resourceType: 'payment',
    resourceId: data.paymentIntentId,
    status: data.status,
    ipAddress: getIpAddress(req),
    userAgent: getUserAgent(req),
    metadata: {
      payment_intent_id: data.paymentIntentId,
      event_id: data.eventId,
      ticket_id: data.ticketId
    },
    amountCents: data.amountCents,
    errorMessage: data.errorMessage,
    errorCode: data.errorCode
  })
}

/**
 * Helper: Log ticket event
 */
export async function logTicketEvent(
  supabase: SupabaseClient,
  req: Request,
  action: EventAction,
  data: {
    userId: string
    userEmail: string
    userRole?: string
    ticketId: string
    ticketNumber: string
    eventId: string
    eventName?: string
    status: Status
    errorMessage?: string
    errorCode?: string
  }
): Promise<void> {
  await createAuditLog(supabase, {
    eventType: 'ticket',
    eventAction: action,
    actionDescription: `Ticket ${action}: ${data.ticketNumber}`,
    severity: data.status === 'failure' ? 'WARN' : 'INFO',
    userId: data.userId,
    userEmail: data.userEmail,
    userRole: data.userRole,
    resourceType: 'ticket',
    resourceId: data.ticketId,
    status: data.status,
    ipAddress: getIpAddress(req),
    userAgent: getUserAgent(req),
    metadata: {
      ticket_number: data.ticketNumber,
      event_id: data.eventId,
      event_name: data.eventName
    },
    errorMessage: data.errorMessage,
    errorCode: data.errorCode
  })
}

/**
 * Helper: Log security event (rate limiting, permission denied, etc.)
 */
export async function logSecurityEvent(
  supabase: SupabaseClient,
  req: Request,
  action: EventAction,
  data: {
    userId?: string
    userEmail?: string
    description: string
    severity?: Severity
    errorCode?: string
    metadata?: Record<string, any>
  }
): Promise<void> {
  await createAuditLog(supabase, {
    eventType: 'security',
    eventAction: action,
    actionDescription: data.description,
    severity: data.severity || 'WARN',
    userId: data.userId,
    userEmail: data.userEmail,
    status: 'failure',
    ipAddress: getIpAddress(req),
    userAgent: getUserAgent(req),
    metadata: data.metadata,
    errorCode: data.errorCode
  })
}

/**
 * Helper: Log admin action (create/update/delete events, venues, users)
 */
export async function logAdminAction(
  supabase: SupabaseClient,
  req: Request,
  action: EventAction,
  data: {
    userId: string
    userEmail: string
    userRole: string
    resourceType: string
    resourceId: string
    description: string
    status: Status
    metadata?: Record<string, any>
  }
): Promise<void> {
  await createAuditLog(supabase, {
    eventType: 'admin',
    eventAction: action,
    actionDescription: data.description,
    severity: 'INFO',
    userId: data.userId,
    userEmail: data.userEmail,
    userRole: data.userRole,
    resourceType: data.resourceType,
    resourceId: data.resourceId,
    status: data.status,
    ipAddress: getIpAddress(req),
    userAgent: getUserAgent(req),
    metadata: data.metadata
  })
}
