const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const crypto = require("crypto");
const { verifyAdminPermission } = require("../shared/permissions");

const db = getFirestore();
const auth = getAuth();

exports.createScanner = onCall(async (request) => {
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const adminClaims = await verifyAdminPermission(request.auth.uid, 'venueAdmin');

    const { displayName, email, venueId = null, venueName = null, notes = null, active = true } = request.data || {};

    if (!displayName || typeof displayName !== 'string') {
      throw new HttpsError("invalid-argument", "Scanner name is required");
    }

    if (!email || typeof email !== 'string') {
      throw new HttpsError("invalid-argument", "Scanner email is required");
    }

    let userRecord;

    try {
      userRecord = await auth.getUserByEmail(email);
    } catch (error) {
      if (error.code === 'auth/user-not-found') {
        const tempPassword = crypto.randomBytes(10).toString('hex');
        userRecord = await auth.createUser({
          email: email,
          password: tempPassword,
          displayName: displayName,
          emailVerified: false
        });
      } else {
        throw error;
      }
    }

    const customClaims = {
      role: 'scanner',
      active: active,
      venueId: venueId || null
    };

    await auth.setCustomUserClaims(userRecord.uid, customClaims);

    const userDocRef = db.collection("users").doc(userRecord.uid);
    const userDoc = await userDocRef.get();
    await userDocRef.set({
      email: email,
      displayName: displayName,
      role: 'scanner',
      provider: 'admin',
      venuePermissions: venueId ? [venueId] : [],
      ...(userDoc.exists ? {} : { createdAt: FieldValue.serverTimestamp() }),
      lastLoginAt: userDoc.exists ? userDoc.data().lastLoginAt || null : null
    }, { merge: true });

    const scannerRef = db.collection("scanners").doc(userRecord.uid);
    const scannerSnapshot = await scannerRef.get();
    await scannerRef.set({
      displayName: displayName,
      email: email,
      venueId: venueId,
      venueName: venueName,
      notes: notes,
      active: active,
      createdAt: scannerSnapshot.exists ? scannerSnapshot.data().createdAt || FieldValue.serverTimestamp() : FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      createdBy: scannerSnapshot.exists ? scannerSnapshot.data().createdBy || request.auth.uid : request.auth.uid,
      createdByRole: scannerSnapshot.exists ? scannerSnapshot.data().createdByRole || adminClaims.role : adminClaims.role
    }, { merge: true });

    return {
      success: true,
      message: `Scanner ${displayName} created`,
      scannerId: scannerRef.id
    };
  } catch (error) {
    console.error("Create scanner error", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", error.message || "Failed to create scanner");
  }
});

exports.setScannerStatus = onCall(async (request) => {
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    await verifyAdminPermission(request.auth.uid, 'venueAdmin');

    const { scannerId, active } = request.data || {};

    if (!scannerId || typeof scannerId !== 'string') {
      throw new HttpsError("invalid-argument", "Scanner ID is required");
    }

    if (typeof active !== 'boolean') {
      throw new HttpsError("invalid-argument", "Active flag must be boolean");
    }

    const scannerRef = db.collection("scanners").doc(scannerId);
    const snapshot = await scannerRef.get();

    if (!snapshot.exists) {
      throw new HttpsError("not-found", "Scanner not found");
    }

    await scannerRef.update({
      active: active,
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: request.auth.uid
    });

    try {
      const userRecord = await auth.getUser(scannerId);
      const claims = userRecord.customClaims || {};
      await auth.setCustomUserClaims(scannerId, {
        ...claims,
        role: 'scanner',
        active: active
      });
    } catch (error) {
      console.warn(\`Unable to update scanner claims for ${scannerId}:\`, error.message);
    }

    await db.collection("users").doc(scannerId).set({
      role: 'scanner',
      active: active,
      updatedAt: FieldValue.serverTimestamp()
    }, { merge: true });

    return { success: true };
  } catch (error) {
    console.error("Set scanner status error", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", error.message || "Failed to update scanner");
  }
});

exports.deleteScanner = onCall(async (request) => {
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    await verifyAdminPermission(request.auth.uid, 'venueAdmin');

    const { scannerId } = request.data || {};

    if (!scannerId || typeof scannerId !== 'string') {
      throw new HttpsError("invalid-argument", "Scanner ID is required");
    }

    const scannerRef = db.collection("scanners").doc(scannerId);
    const snapshot = await scannerRef.get();

    if (!snapshot.exists) {
      throw new HttpsError("not-found", "Scanner not found");
    }

    await scannerRef.delete();

    try {
      const userRecord = await auth.getUser(scannerId);
      const claims = userRecord.customClaims || {};
      const updatedClaims = { ...claims };
      delete updatedClaims.venueId;
      updatedClaims.role = 'user';
      updatedClaims.active = false;
      await auth.setCustomUserClaims(scannerId, updatedClaims);
    } catch (error) {
      console.warn(\`Unable to reset claims for scanner ${scannerId}:\`, error.message);
    }

    await db.collection("users").doc(scannerId).set({
      role: 'user',
      active: false,
      venuePermissions: [],
      updatedAt: FieldValue.serverTimestamp()
    }, { merge: true });

    return { success: true };
  } catch (error) {
    console.error("Delete scanner error", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", error.message || "Failed to delete scanner");
  }
});

