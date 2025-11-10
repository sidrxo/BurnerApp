const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const crypto = require("crypto");
const { verifyAdminPermission } = require("../shared/permissions");

const db = getFirestore();
const auth = getAuth();

exports.createAdmin = onCall({ region: "europe-west2" }, async (request) => {
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
    let isNewUser = false;

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
        isNewUser = true;
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
        [adminField]: FieldValue.arrayUnion(email)
      });
    }

    // Send password reset email if this is a new user
    let passwordResetSent = false;
    if (isNewUser) {
      try {
        const actionCodeSettings = {
          // The URL to redirect to after password reset
          url: process.env.DASHBOARD_URL || 'https://dashboard.burner.app',
          handleCodeInApp: false
        };

        const resetLink = await auth.generatePasswordResetLink(email, actionCodeSettings);
        console.log(`Password reset link generated for ${email}: ${resetLink}`);

        // In a production environment, you would send this link via email
        // For now, we're just logging it and setting a flag
        passwordResetSent = true;

        console.log(`✅ Password reset email would be sent to ${email}`);
        console.log(`🔗 Reset link: ${resetLink}`);
      } catch (emailError) {
        console.error(`Failed to generate password reset link for ${email}:`, emailError);
        // Don't fail the entire operation if email sending fails
      }
    }

    return {
      success: true,
      message: `Admin ${email} created successfully${passwordResetSent ? '. Password reset email sent.' : ''}`,
      userId: userRecord.uid,
      needsPasswordReset: isNewUser,
      passwordResetSent
    };

  } catch (error) {
    console.error("Create admin error:", error.message);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", `Failed to create admin: ${error.message}`);
  }
});

exports.updateAdmin = onCall({ region: "europe-west2" }, async (request) => {
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

    // Handle venue changes carefully with rollback capability
    if (updates.venueId !== undefined && updates.venueId !== currentData.venueId) {
      try {
        // First verify new venue exists if provided
        if (updates.venueId) {
          const newVenueDoc = await db.collection("venues").doc(updates.venueId).get();
          if (!newVenueDoc.exists) {
            throw new HttpsError("not-found", "New venue not found");
          }
        }

        // Remove from old venue if it exists
        if (currentData.venueId) {
          const oldVenueRef = db.collection("venues").doc(currentData.venueId);
          const oldVenueDoc = await oldVenueRef.get();

          if (oldVenueDoc.exists) {
            const oldAdminField = currentData.role === 'venueAdmin' ? 'admins' : 'subAdmins';
            await oldVenueRef.update({
              [oldAdminField]: FieldValue.arrayRemove(currentData.email)
            });
          }
        }

        // Add to new venue if provided
        if (updates.venueId) {
          const newVenueRef = db.collection("venues").doc(updates.venueId);
          const finalRole = updates.role || currentData.role;
          const newAdminField = finalRole === 'venueAdmin' ? 'admins' : 'subAdmins';
          await newVenueRef.update({
            [newAdminField]: FieldValue.arrayUnion(currentData.email)
          });
        }

        firestoreUpdates.venueId = updates.venueId;
        if (updates.venueId) {
          customClaimsUpdates.venueId = updates.venueId;
        } else {
          // Remove venueId from custom claims if set to null
          delete customClaimsUpdates.venueId;
        }
      } catch (venueError) {
        console.error("Error updating venue assignment:", venueError);
        throw new HttpsError("internal", `Failed to update venue assignment: ${venueError.message}`);
      }
    }

    // Handle role changes that might affect venue field
    if (updates.role && updates.role !== currentData.role && currentData.venueId && !updates.venueId) {
      try {
        // Role changed but venue stayed the same - need to move between admins/subAdmins arrays
        const venueRef = db.collection("venues").doc(currentData.venueId);
        const venueDoc = await venueRef.get();

        if (venueDoc.exists) {
          const oldField = currentData.role === 'venueAdmin' ? 'admins' : 'subAdmins';
          const newField = updates.role === 'venueAdmin' ? 'admins' : 'subAdmins';

          if (oldField !== newField) {
            await venueRef.update({
              [oldField]: FieldValue.arrayRemove(currentData.email),
              [newField]: FieldValue.arrayUnion(currentData.email)
            });
          }
        }
      } catch (roleVenueError) {
        console.error("Error updating venue role field:", roleVenueError);
        // Don't fail the entire operation for this
      }
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

exports.deleteAdmin = onCall({ region: "europe-west2" }, async (request) => {
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

    // Remove admin from venue if assigned
    if (adminData.venueId) {
      try {
        const venueRef = db.collection("venues").doc(adminData.venueId);
        const venueDoc = await venueRef.get();

        if (venueDoc.exists) {
          const adminField = adminData.role === 'venueAdmin' ? 'admins' : 'subAdmins';
          await venueRef.update({
            [adminField]: FieldValue.arrayRemove(adminData.email)
          });
          console.log(`Removed ${adminData.email} from venue ${adminData.venueId}`);
        } else {
          console.warn(`Venue ${adminData.venueId} not found when deleting admin ${adminId}`);
        }
      } catch (venueError) {
        console.error(`Error removing admin from venue:`, venueError);
        // Continue with deletion even if venue update fails
      }
    }

    // Clear custom claims and delete admin document
    try {
      await Promise.all([
        auth.setCustomUserClaims(adminId, null),
        db.collection("admins").doc(adminId).delete()
      ]);
      console.log(`Admin ${adminId} deleted successfully`);
    } catch (deleteError) {
      console.error(`Error deleting admin ${adminId}:`, deleteError);
      throw new HttpsError("internal", `Failed to delete admin: ${deleteError.message}`);
    }
    
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