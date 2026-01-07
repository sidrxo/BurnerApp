/**
 * Simple in-memory rate limiter for edge functions
 * Production: Consider using Upstash Redis or similar for distributed rate limiting
 */

interface RateLimitEntry {
  count: number
  resetAt: number
}

// In-memory store (resets on cold starts)
const rateLimitStore = new Map<string, RateLimitEntry>()

// Cleanup old entries every 5 minutes
setInterval(() => {
  const now = Date.now()
  for (const [key, entry] of rateLimitStore.entries()) {
    if (entry.resetAt < now) {
      rateLimitStore.delete(key)
    }
  }
}, 5 * 60 * 1000)

export interface RateLimitConfig {
  maxRequests: number  // Maximum requests allowed
  windowMs: number     // Time window in milliseconds
}

export interface RateLimitResult {
  success: boolean
  remaining: number
  resetAt: number
  retryAfter?: number
}

/**
 * Check if request is within rate limit
 * @param identifier Unique identifier (e.g., userId, IP address)
 * @param config Rate limit configuration
 */
export function checkRateLimit(
  identifier: string,
  config: RateLimitConfig
): RateLimitResult {
  const now = Date.now()
  const key = `ratelimit:${identifier}`

  let entry = rateLimitStore.get(key)

  // If no entry or expired, create new one
  if (!entry || entry.resetAt < now) {
    entry = {
      count: 1,
      resetAt: now + config.windowMs
    }
    rateLimitStore.set(key, entry)

    return {
      success: true,
      remaining: config.maxRequests - 1,
      resetAt: entry.resetAt
    }
  }

  // Increment counter
  entry.count++

  // Check if limit exceeded
  if (entry.count > config.maxRequests) {
    return {
      success: false,
      remaining: 0,
      resetAt: entry.resetAt,
      retryAfter: Math.ceil((entry.resetAt - now) / 1000)
    }
  }

  return {
    success: true,
    remaining: config.maxRequests - entry.count,
    resetAt: entry.resetAt
  }
}

/**
 * Create rate limit response with headers
 */
export function createRateLimitResponse(
  result: RateLimitResult,
  headers: Record<string, string> = {}
): Response {
  return new Response(
    JSON.stringify({
      success: false,
      message: 'Rate limit exceeded',
      retryAfter: result.retryAfter
    }),
    {
      status: 429,
      headers: {
        ...headers,
        'Content-Type': 'application/json',
        'X-RateLimit-Limit': String(result.remaining + (result.success ? 0 : 1)),
        'X-RateLimit-Remaining': String(result.remaining),
        'X-RateLimit-Reset': String(result.resetAt),
        'Retry-After': String(result.retryAfter || 60)
      }
    }
  )
}

/**
 * Extract identifier from request (IP or user ID)
 */
export function getRequestIdentifier(
  req: Request,
  userId?: string
): string {
  // Prefer user ID for authenticated requests
  if (userId) {
    return `user:${userId}`
  }

  // Fallback to IP address
  const ip = req.headers.get('x-forwarded-for') ||
             req.headers.get('x-real-ip') ||
             'unknown'

  return `ip:${ip}`
}

// Common rate limit configurations
export const RATE_LIMITS = {
  // Strict limits for sensitive operations
  PAYMENT: { maxRequests: 5, windowMs: 60 * 1000 },        // 5 req/min
  TICKET_SCAN: { maxRequests: 30, windowMs: 60 * 1000 },   // 30 req/min

  // Standard limits for regular operations
  STANDARD: { maxRequests: 60, windowMs: 60 * 1000 },      // 60 req/min

  // Lenient limits for read operations
  READ: { maxRequests: 100, windowMs: 60 * 1000 },         // 100 req/min
}
