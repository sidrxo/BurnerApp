const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const crypto = require("crypto");
const { verifyAdminPermission } = require("../shared/permissions");

const db = getFirestore();
const auth = getAuth();

/**
 * Create a new scanner account
 * Sets custom claims for role-based access control
 */
exports.createScanner = onCall(async (request) => {
  console.log("=== CREATE SCANNER FUNCTION START ===");
  
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    // Verify caller has admin permissions
    await verifyAdminPermission(request.auth.uid, 'siteAdmin');

    const { email, name, venueId } = request.data;

    if (!email || !name) {
      throw new HttpsError("invalid-argument", "Email and name are required");
    }

    // Validate venue exists if venueId provided
    if (venueId) {
      const venueDoc = await db.collection("venues").doc(venueId).get();
      if (!venueDoc.exists) {
        throw new HttpsError("not-found", "Venue not found");
      }
    }

    let userRecord;
    
    try {
      // Check if user already exists
      userRecord = await auth.getUserByEmail(email);
      console.log("User already exists:", userRecord.uid);
    } catch (error) {
      if (error.code === 'auth/user-not-found') {
        // Create new user with temporary password
        const tempPassword = crypto.randomBytes(12).toString('hex');
        userRecord = await auth.createUser({
          email: email,
          password: tempPassword,
          displayName: name,
          emailVerified: false
        });
        console.log("Created new scanner user:", userRecord.uid);
      } else {
        throw error;
      }
    }

    // ✅ SET CUSTOM CLAIMS (This is the key improvement)
    const customClaims = {
      role: 'scanner',
      active: true,
      venueId: venueId || null  // null = site-wide scanner
    };

    await auth.setCustomUserClaims(userRecord.uid, customClaims);
    console.log("Custom claims set:", customClaims);

    // Store scanner profile in Firestore
    await db.collection("scanners").doc(userRecord.uid).set({
      email: email,
      name: name,
      venueId: venueId || null,
      active: true,
      createdAt: FieldValue.serverTimestamp(),
      createdBy: request.auth.uid,
      needsPasswordReset: !userRecord.emailVerified
    });

    console.log("Scanner created successfully:", userRecord.uid);
    
    return {
      success: true,
      message: `Scanner ${email} created successfully`,
      scannerId: userRecord.uid,
      needsPasswordReset: !userRecord.emailVerified
    };

  } catch (error) {
    console.error("Create scanner error:", error.message);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", `Failed to create scanner: ${error.message}`);
  }
});

/**
 * Update an existing scanner
 * Updates both Firestore document and custom claims
 */
exports.updateScanner = onCall(async (request) => {
  console.log("=== UPDATE SCANNER FUNCTION START ===");
  
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    await verifyAdminPermission(request.auth.uid, 'siteAdmin');

    const { scannerId, updates } = request.data;

    if (!scannerId) {
      throw new HttpsError("invalid-argument", "Scanner ID is required");
    }

    // Verify scanner exists
    const scannerDoc = await db.collection("scanners").doc(scannerId).get();
    if (!scannerDoc.exists) {
      throw new HttpsError("not-found", "Scanner not found");
    }

    const currentData = scannerDoc.data();
    const userRecord = await auth.getUser(scannerId);

    // Prepare Firestore updates
    const firestoreUpdates = {
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: request.auth.uid
    };

    // Prepare custom claims updates
    const customClaimsUpdates = {
      role: 'scanner',
      active: currentData.active,
      venueId: currentData.venueId
    };

    // Update name
    if (updates.name && updates.name !== currentData.name) {
      firestoreUpdates.name = updates.name;
      await auth.updateUser(scannerId, { displayName: updates.name });
    }

    // Update email
    if (updates.email && updates.email !== currentData.email) {
      firestoreUpdates.email = updates.email;
      await auth.updateUser(scannerId, { email: updates.email });
    }

    // Update venue
    if (updates.venueId !== undefined && updates.venueId !== currentData.venueId) {
      // Validate new venue exists
      if (updates.venueId) {
        const venueDoc = await db.collection("venues").doc(updates.venueId).get();
        if (!venueDoc.exists) {
          throw new HttpsError("not-found", "New venue not found");
        }
      }
      
      firestoreUpdates.venueId = updates.venueId;
      customClaimsUpdates.venueId = updates.venueId;
    }

    // Update active status
    if (typeof updates.active === 'boolean' && updates.active !== currentData.active) {
      firestoreUpdates.active = updates.active;
      customClaimsUpdates.active = updates.active;
    }

    // Apply updates
    await Promise.all([
      db.collection("scanners").doc(scannerId).update(firestoreUpdates),
      auth.setCustomUserClaims(scannerId, customClaimsUpdates)
    ]);

    console.log("Scanner updated successfully:", scannerId);
    
    return {
      success: true,
      message: "Scanner updated successfully"
    };

  } catch (error) {
    console.error("Update scanner error:", error.message);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", `Failed to update scanner: ${error.message}`);
  }
});

/**
 * Delete a scanner account
 * Removes both Firestore document and Auth user
 */
exports.deleteScanner = onCall(async (request) => {
  console.log("=== DELETE SCANNER FUNCTION START ===");
  
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    await verifyAdminPermission(request.auth.uid, 'siteAdmin');

    const { scannerId } = request.data;

    if (!scannerId) {
      throw new HttpsError("invalid-argument", "Scanner ID is required");
    }

    // Verify scanner exists
    const scannerDoc = await db.collection("scanners").doc(scannerId).get();
    if (!scannerDoc.exists) {
      throw new HttpsError("not-found", "Scanner not found");
    }

    // Delete in parallel for efficiency
    await Promise.all([
      auth.deleteUser(scannerId),
      db.collection("scanners").doc(scannerId).delete()
    ]);

    console.log("Scanner deleted successfully:", scannerId);
    
    return {
      success: true,
      message: "Scanner deleted successfully"
    };

  } catch (error) {
    console.error("Delete scanner error:", error.message);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", `Failed to delete scanner: ${error.message}`);
  }
});

/**
 * Get scanner profile with custom claims
 * Useful for verifying scanner permissions
 */
exports.getScannerProfile = onCall(async (request) => {
  console.log("=== GET SCANNER PROFILE FUNCTION START ===");
  
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const scannerId = request.data?.scannerId || request.auth.uid;

    // Only allow access to own profile or by admins
    if (scannerId !== request.auth.uid) {
      await verifyAdminPermission(request.auth.uid, 'siteAdmin');
    }

    const [scannerDoc, userRecord] = await Promise.all([
      db.collection("scanners").doc(scannerId).get(),
      auth.getUser(scannerId)
    ]);

    if (!scannerDoc.exists) {
      throw new HttpsError("not-found", "Scanner not found");
    }

    const scannerData = scannerDoc.data();
    const customClaims = userRecord.customClaims || {};

    return {
      success: true,
      scanner: {
        id: scannerId,
        email: scannerData.email,
        name: scannerData.name,
        venueId: scannerData.venueId,
        active: scannerData.active,
        role: customClaims.role,
        customClaims: customClaims,
        createdAt: scannerData.createdAt,
        lastActiveAt: scannerData.lastActiveAt
      }
    };

  } catch (error) {
    console.error("Get scanner profile error:", error.message);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", `Failed to get scanner profile: ${error.message}`);
  }
});