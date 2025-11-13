const { HttpsError } = require("firebase-functions/v2/https");
const { getAuth } = require("firebase-admin/auth");

const auth = getAuth();

/**
 * Verify user has required admin permission level
 * @param {string} uid - User ID to verify
 * @param {string} requiredRole - Minimum required role ('siteAdmin', 'venueAdmin', 'subAdmin')
 * @returns {Object} User's custom claims
 */
async function verifyAdminPermission(uid, requiredRole = 'siteAdmin') {
  try {
    const user = await auth.getUser(uid);
    const customClaims = user.customClaims || {};
    
    if (!customClaims.role) {
      throw new HttpsError("permission-denied", "No role assigned");
    }

    const roleHierarchy = {
      'siteAdmin': 3,
      'venueAdmin': 2, 
      'subAdmin': 1
    };

    const userLevel = roleHierarchy[customClaims.role] || 0;
    const requiredLevel = roleHierarchy[requiredRole] || 0;

    if (userLevel < requiredLevel) {
      throw new HttpsError(
        "permission-denied", 
        `Insufficient permissions. Required: ${requiredRole}, Have: ${customClaims.role}`
      );
    }

    return customClaims;
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Failed to verify permissions");
  }
}

/**
 * Validate user has access to specific venue
 * @param {Object} userClaims - User's custom claims
 * @param {string} targetVenueId - Venue ID to check access for
 * @returns {boolean} True if user has access
 */
function validateVenueAccess(userClaims, targetVenueId) {
  // Site admins have access to all venues
  if (userClaims.role === 'siteAdmin') {
    return true;
  }
  
  // Venue admins and scanners must match venueId
  if (['venueAdmin', 'subAdmin', 'scanner'].includes(userClaims.role)) {
    // null venueId means site-wide access
    if (userClaims.venueId === null) {
      return true;
    }
    return userClaims.venueId === targetVenueId;
  }
  
  return false;
}

/**
 * Check if user is a scanner with proper permissions
 * @param {string} uid - User ID to check
 * @param {string} venueId - Optional venue ID to validate access
 * @returns {Promise<Object>} Scanner claims if valid
 */
async function verifyScannerPermission(uid, venueId = null) {
  const user = await auth.getUser(uid);
  const customClaims = user.customClaims || {};
  
  // Allow site admins OR scanners
  if (!['siteAdmin', 'scanner'].includes(customClaims.role)) {
    throw new HttpsError("permission-denied", "Scanner or admin role required");
  }

  if (!customClaims.active && customClaims.role === 'scanner') {
    throw new HttpsError("permission-denied", "Scanner account is inactive");
  }

  // If venueId specified, validate access (site admins bypass this)
  if (venueId && !validateVenueAccess(customClaims, venueId)) {
    throw new HttpsError(
      "permission-denied", 
      "Scanner does not have access to this venue"
    );
  }

  return customClaims;
}

/**
 * Require user to be authenticated
 * @param {Object} request - Cloud Functions request object
 * @throws {HttpsError} If user is not authenticated
 */
function requireAuth(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }
}

/**
 * Require user to be a site admin
 * @param {Object} request - Cloud Functions request object
 * @throws {HttpsError} If user is not authenticated or not a site admin
 */
async function requireSiteAdmin(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }

  await verifyAdminPermission(request.auth.uid, 'siteAdmin');
}

module.exports = {
  verifyAdminPermission,
  validateVenueAccess,
  verifyScannerPermission,
  requireAuth,
  requireSiteAdmin
};