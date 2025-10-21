const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");

const db = getFirestore();
const auth = getAuth();

exports.validateUser = onCall(async (request) => {
  console.log("=== VALIDATE USER FUNCTION START ===");
  
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const userId = request.auth.uid;
    const userRecord = await auth.getUser(userId);

    // If no custom claims, set default user role
    if (!userRecord.customClaims || !userRecord.customClaims.role) {
      await auth.setCustomUserClaims(userId, { role: 'user', active: true });
      console.log(`Set default role for user ${userId}`);
    } else {
      // Validate admin/scanner roles against Firestore
      const role = userRecord.customClaims.role;
      
      if (['siteAdmin', 'venueAdmin', 'subAdmin'].includes(role)) {
        const adminDoc = await db.collection("admins").doc(userId).get();
        
        if (!adminDoc.exists || !adminDoc.data().active) {
          await auth.setCustomUserClaims(userId, { role: 'user', active: true });
          console.log(`Revoked admin privileges for ${userId}`);
        }
      } else if (role === 'scanner') {
        // ✅ Validate scanner role
        const scannerDoc = await db.collection("scanners").doc(userId).get();
        
        if (!scannerDoc.exists || !scannerDoc.data().active) {
          await auth.setCustomUserClaims(userId, { role: 'user', active: true });
          console.log(`Revoked scanner privileges for ${userId}`);
        }
      }
    }

    const updatedUser = await auth.getUser(userId);
    
    return {
      success: true,
      user: {
        uid: userId,
        email: userRecord.email,
        role: updatedUser.customClaims?.role || 'user',
        venueId: updatedUser.customClaims?.venueId || null,
        active: updatedUser.customClaims?.active !== false
      }
    };

  } catch (error) {
    console.error("Validate user error:", error.message);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", `Failed to validate user: ${error.message}`);
  }
});