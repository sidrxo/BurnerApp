const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const crypto = require("crypto");
const { verifyAdminPermission } = require("../shared/permissions");

const db = getFirestore();
const auth = getAuth();

exports.createAdmin = onCall(async (request) => {
  console.log("=== CREATE ADMIN FUNCTION START ===");
  
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    await verifyAdminPermission(request.auth.uid, 'siteAdmin');

    const { email, name, role, venueId } = request.data;

    if (!email || !name || !role) {
      throw new HttpsError("invalid-argument", "Email, name, and role are required");
    }

    if (!['siteAdmin', 'venueAdmin', 'subAdmin'].includes(role)) {
      throw new HttpsError("invalid-argument", "Invalid role specified");
    }

    if ((role === 'venueAdmin' || role === 'subAdmin') && !venueId) {
      throw new HttpsError("invalid-argument", "Venue ID required for venue admins");
    }

    if (venueId) {
      const venueDoc = await db.collection("venues").doc(venueId).get();
      if (!venueDoc.exists) {
        throw new HttpsError("not-found", "Venue not found");
      }
    }

    let userRecord;
    
    try {
      userRecord = await auth.getUserByEmail(email);
    } catch (error) {
      if (error.code === 'auth/user-not-found') {
        const tempPassword = crypto.randomBytes(12).toString('hex');
        userRecord = await auth.createUser({
          email: email,
          password: tempPassword,
          displayName: name,
          emailVerified: false
        });
      } else {
        throw error;
      }
    }

    const customClaims = {
      role: role,
      active: true,
      ...(venueId && { venueId: venueId })
    };

    await auth.setCustomUserClaims(userRecord.uid, customClaims);

    await db.collection("admins").doc(userRecord.uid).set({
      email: email,
      name: name,
      role: role,
      venueId: venueId || null,
      active: true,
      createdAt: new Date(),
      createdBy: request.auth.uid,
      needsPasswordReset: !userRecord.emailVerified
    });

    if (venueId) {
      const venueRef = db.collection("venues").doc(venueId);
      const adminField = role === 'venueAdmin' ? 'admins' : 'subAdmins';
      await venueRef.update({
        [adminField]: db.FieldValue.arrayUnion(email)
      });
    }
    
    return {
      success: true,
      message: `Admin ${email} created successfully`,
      userId: userRecord.uid,
      needsPasswordReset: !userRecord.emailVerified
    };

  } catch (error) {
    console.error("Create admin error:", error.message);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", `Failed to create admin: ${error.message}`);
  }
});

exports.updateAdmin = onCall(async (request) => {
  console.log("=== UPDATE ADMIN FUNCTION START ===");
  
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    await verifyAdminPermission(request.auth.uid, 'siteAdmin');

    const { adminId, updates } = request.data;

    if (!adminId) {
      throw new HttpsError("invalid-argument", "Admin ID is required");
    }

    const adminDoc = await db.collection("admins").doc(adminId).get();
    if (!adminDoc.exists) {
      throw new HttpsError("not-found", "Admin not found");
    }

    const currentData = adminDoc.data();
    const userRecord = await auth.getUser(adminId);

    const firestoreUpdates = {
      updatedAt: new Date(),
      updatedBy: request.auth.uid
    };

    const customClaimsUpdates = { ...userRecord.customClaims };

    if (updates.role && updates.role !== currentData.role) {
      if (!['siteAdmin', 'venueAdmin', 'subAdmin'].includes(updates.role)) {
        throw new HttpsError("invalid-argument", "Invalid role");
      }
      firestoreUpdates.role = updates.role;
      customClaimsUpdates.role = updates.role;
    }

    if (typeof updates.active === 'boolean' && updates.active !== currentData.active) {
      firestoreUpdates.active = updates.active;
      customClaimsUpdates.active = updates.active;
    }

    if (updates.venueId !== undefined && updates.venueId !== currentData.venueId) {
      if (currentData.venueId) {
        const oldVenueRef = db.collection("venues").doc(currentData.venueId);
        const oldAdminField = currentData.role === 'venueAdmin' ? 'admins' : 'subAdmins';
        await oldVenueRef.update({
          [oldAdminField]: db.FieldValue.arrayRemove(currentData.email)
        });
      }

      if (updates.venueId) {
        const newVenueDoc = await db.collection("venues").doc(updates.venueId).get();
        if (!newVenueDoc.exists) {
          throw new HttpsError("not-found", "New venue not found");
        }
        
        const newVenueRef = db.collection("venues").doc(updates.venueId);
        const newAdminField = (updates.role || currentData.role) === 'venueAdmin' ? 'admins' : 'subAdmins';
        await newVenueRef.update({
          [newAdminField]: db.FieldValue.arrayUnion(currentData.email)
        });
      }

      firestoreUpdates.venueId = updates.venueId;
      customClaimsUpdates.venueId = updates.venueId;
    }

    await Promise.all([
      db.collection("admins").doc(adminId).update(firestoreUpdates),
      auth.setCustomUserClaims(adminId, customClaimsUpdates)
    ]);
    
    return {
      success: true,
      message: "Admin updated successfully"
    };

  } catch (error) {
    console.error("Update admin error:", error.message);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", `Failed to update admin: ${error.message}`);
  }
});

exports.deleteAdmin = onCall(async (request) => {
  console.log("=== DELETE ADMIN FUNCTION START ===");
  
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    await verifyAdminPermission(request.auth.uid, 'siteAdmin');

    const { adminId } = request.data;

    if (!adminId) {
      throw new HttpsError("invalid-argument", "Admin ID is required");
    }

    if (adminId === request.auth.uid) {
      throw new HttpsError("failed-precondition", "Cannot delete your own admin account");
    }

    const adminDoc = await db.collection("admins").doc(adminId).get();
    if (!adminDoc.exists) {
      throw new HttpsError("not-found", "Admin not found");
    }

    const adminData = adminDoc.data();

    if (adminData.venueId) {
      const venueRef = db.collection("venues").doc(adminData.venueId);
      const adminField = adminData.role === 'venueAdmin' ? 'admins' : 'subAdmins';
      await venueRef.update({
        [adminField]: db.FieldValue.arrayRemove(adminData.email)
      });
    }

    await Promise.all([
      auth.setCustomUserClaims(adminId, null),
      db.collection("admins").doc(adminId).delete()
    ]);
    
    return {
      success: true,
      message: "Admin deleted successfully"
    };

  } catch (error) {
    console.error("Delete admin error:", error.message);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", `Failed to delete admin: ${error.message}`);
  }
});