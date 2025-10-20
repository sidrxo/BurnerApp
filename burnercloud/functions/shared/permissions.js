const { HttpsError } = require("firebase-functions/v2/https");
const { getAuth } = require("firebase-admin/auth");

const auth = getAuth();

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
      throw new HttpsError("permission-denied", `Insufficient permissions. Required: ${requiredRole}`);
    }

    return customClaims;
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Failed to verify permissions");
  }
}

function validateVenueAccess(userClaims, targetVenueId) {
  if (userClaims.role === 'siteAdmin') return true;
  if (userClaims.role === 'venueAdmin' || userClaims.role === 'subAdmin') {
    return userClaims.venueId === targetVenueId;
  }
  return false;
}

module.exports = {
  verifyAdminPermission,
  validateVenueAccess
};