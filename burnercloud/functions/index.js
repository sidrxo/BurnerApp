const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const crypto = require("crypto");

initializeApp();
const db = getFirestore();
const auth = getAuth();

// Helper function to verify admin permissions
async function verifyAdminPermission(uid, requiredRole = 'siteAdmin') {
  try {
    const user = await auth.getUser(uid);
    const customClaims = user.customClaims || {};
    
    if (!customClaims.role) {
      throw new HttpsError("permission-denied", "No role assigned");
    }

    // Role hierarchy: siteAdmin > venueAdmin > subAdmin
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

// Helper function to validate venue access
function validateVenueAccess(userClaims, targetVenueId) {
  if (userClaims.role === 'siteAdmin') return true;
  if (userClaims.role === 'venueAdmin' || userClaims.role === 'subAdmin') {
    return userClaims.venueId === targetVenueId;
  }
  return false;
}

// ============ SECURE ADMIN MANAGEMENT FUNCTIONS ============

// Create Admin with Custom Claims
exports.createAdmin = onCall(async (request) => {
  console.log("=== CREATE ADMIN FUNCTION START ===");
  
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    // Only siteAdmins can create admins
    await verifyAdminPermission(request.auth.uid, 'siteAdmin');

    const { email, name, role, venueId } = request.data;

    // Validate input
    if (!email || !name || !role) {
      throw new HttpsError("invalid-argument", "Email, name, and role are required");
    }

    if (!['siteAdmin', 'venueAdmin', 'subAdmin'].includes(role)) {
      throw new HttpsError("invalid-argument", "Invalid role specified");
    }

    if ((role === 'venueAdmin' || role === 'subAdmin') && !venueId) {
      throw new HttpsError("invalid-argument", "Venue ID required for venue admins");
    }

    // Check if venue exists (if applicable)
    if (venueId) {
      const venueDoc = await db.collection("venues").doc(venueId).get();
      if (!venueDoc.exists) {
        throw new HttpsError("not-found", "Venue not found");
      }
    }

    let userRecord;
    
    try {
      // Try to get existing user
      userRecord = await auth.getUserByEmail(email);
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
        
        console.log(`Created new user ${email} with temp password`);
      } else {
        throw error;
      }
    }

    // Set custom claims
    const customClaims = {
      role: role,
      active: true,
      ...(venueId && { venueId: venueId })
    };

    await auth.setCustomUserClaims(userRecord.uid, customClaims);

    // Create admin document in Firestore
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

    // Update venue admin lists if applicable
    if (venueId) {
      const venueRef = db.collection("venues").doc(venueId);
      const adminField = role === 'venueAdmin' ? 'admins' : 'subAdmins';
      
      await venueRef.update({
        [adminField]: db.FieldValue.arrayUnion(email)
      });
    }

    console.log(`Admin ${email} created successfully with role ${role}`);
    
    return {
      success: true,
      message: `Admin ${email} created successfully. They will need to reset their password.`,
      userId: userRecord.uid,
      needsPasswordReset: !userRecord.emailVerified
    };

  } catch (error) {
    console.error("Create admin error:", error.message);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", `Failed to create admin: ${error.message}`);
  }
});

// Update Admin Role/Status
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

    // Get current admin data
    const adminDoc = await db.collection("admins").doc(adminId).get();
    if (!adminDoc.exists) {
      throw new HttpsError("not-found", "Admin not found");
    }

    const currentData = adminDoc.data();
    const userRecord = await auth.getUser(adminId);

    // Prepare updates
    const firestoreUpdates = {
      updatedAt: new Date(),
      updatedBy: request.auth.uid
    };

    const customClaimsUpdates = { ...userRecord.customClaims };

    // Handle role change
    if (updates.role && updates.role !== currentData.role) {
      if (!['siteAdmin', 'venueAdmin', 'subAdmin'].includes(updates.role)) {
        throw new HttpsError("invalid-argument", "Invalid role");
      }
      firestoreUpdates.role = updates.role;
      customClaimsUpdates.role = updates.role;
    }

    // Handle active status change
    if (typeof updates.active === 'boolean' && updates.active !== currentData.active) {
      firestoreUpdates.active = updates.active;
      customClaimsUpdates.active = updates.active;
    }

    // Handle venue change
    if (updates.venueId !== undefined && updates.venueId !== currentData.venueId) {
      // Remove from old venue
      if (currentData.venueId) {
        const oldVenueRef = db.collection("venues").doc(currentData.venueId);
        const oldAdminField = currentData.role === 'venueAdmin' ? 'admins' : 'subAdmins';
        await oldVenueRef.update({
          [oldAdminField]: db.FieldValue.arrayRemove(currentData.email)
        });
      }

      // Add to new venue
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

    // Apply updates
    await Promise.all([
      db.collection("admins").doc(adminId).update(firestoreUpdates),
      auth.setCustomUserClaims(adminId, customClaimsUpdates)
    ]);

    console.log(`Admin ${adminId} updated successfully`);
    
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

// Delete Admin
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

    // Can't delete yourself
    if (adminId === request.auth.uid) {
      throw new HttpsError("failed-precondition", "Cannot delete your own admin account");
    }

    // Get admin data before deletion
    const adminDoc = await db.collection("admins").doc(adminId).get();
    if (!adminDoc.exists) {
      throw new HttpsError("not-found", "Admin not found");
    }

    const adminData = adminDoc.data();

    // Remove from venue admin lists
    if (adminData.venueId) {
      const venueRef = db.collection("venues").doc(adminData.venueId);
      const adminField = adminData.role === 'venueAdmin' ? 'admins' : 'subAdmins';
      await venueRef.update({
        [adminField]: db.FieldValue.arrayRemove(adminData.email)
      });
    }

    // Remove custom claims and delete admin document
    await Promise.all([
      auth.setCustomUserClaims(adminId, null),
      db.collection("admins").doc(adminId).delete()
    ]);

    console.log(`Admin ${adminId} deleted successfully`);
    
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

// ============ VENUE MANAGEMENT FUNCTIONS ============

// Create Venue (Site Admin Only)
exports.createVenue = onCall(async (request) => {
  console.log("=== CREATE VENUE FUNCTION START ===");
  
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    await verifyAdminPermission(request.auth.uid, 'siteAdmin');

    const { name, adminEmail } = request.data;

    if (!name || !adminEmail) {
      throw new HttpsError("invalid-argument", "Venue name and admin email are required");
    }

    // Create venue document
    const venueRef = await db.collection("venues").add({
      name: name.trim(),
      admins: [adminEmail.trim()],
      subAdmins: [],
      createdAt: new Date(),
      createdBy: request.auth.uid,
      active: true
    });

    console.log(`Venue ${name} created with ID ${venueRef.id}`);
    
    return {
      success: true,
      venueId: venueRef.id,
      message: `Venue "${name}" created successfully`
    };

  } catch (error) {
    console.error("Create venue error:", error.message);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", `Failed to create venue: ${error.message}`);
  }
});

// ============ USER VALIDATION FUNCTIONS ============

// Validate and sync user on login
exports.validateUser = onCall(async (request) => {
  console.log("=== VALIDATE USER FUNCTION START ===");
  
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const userId = request.auth.uid;
    const userRecord = await auth.getUser(userId);

    // Check if user has custom claims
    if (!userRecord.customClaims || !userRecord.customClaims.role) {
      // Set default user role
      await auth.setCustomUserClaims(userId, { role: 'user', active: true });
    } else {
      // Validate admin status
      if (['siteAdmin', 'venueAdmin', 'subAdmin'].includes(userRecord.customClaims.role)) {
        const adminDoc = await db.collection("admins").doc(userId).get();
        
        if (!adminDoc.exists || !adminDoc.data().active) {
          // Admin document doesn't exist or is inactive - revoke admin privileges
          await auth.setCustomUserClaims(userId, { role: 'user', active: true });
          console.log(`Revoked admin privileges for ${userId}`);
        }
      }
    }

    // Get updated claims
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

// ============ YOUR EXISTING TICKET FUNCTIONS ============
// (Keep all your existing ticket functions - purchaseTicket, checkUserTicket, getUserTickets)

// Enhanced QR Code Generation
function generateQRCodeData(ticketId, eventId, userId, ticketNumber) {
  try {
    const qrData = {
      type: "EVENT_TICKET",
      ticketId: ticketId,
      eventId: eventId,
      userId: userId,
      ticketNumber: ticketNumber,
      timestamp: Date.now(),
      version: "1.0",
      hash: generateSecurityHash(ticketId, eventId, userId)
    };
    
    return JSON.stringify(qrData);
  } catch (error) {
    console.error("QR Code generation error:", error.message);
    return `TICKET:${ticketId}:EVENT:${eventId}:USER:${userId}:NUMBER:${ticketNumber}`;
  }
}

function generateSecurityHash(ticketId, eventId, userId) {
  try {
    const secret = process.env.QR_SECRET || "default_secret_change_in_production";
    const data = `${ticketId}:${eventId}:${userId}`;
    return crypto.createHmac('sha256', secret).update(data).digest('hex').substring(0, 16);
  } catch (error) {
    console.error("Hash generation error:", error.message);
    return "fallback_hash";
  }
}

function generateTicketNumber() {
  try {
    const timestamp = Date.now().toString().slice(-6);
    const random = Math.floor(Math.random() * 1000).toString().padStart(3, "0");
    const checksum = (parseInt(timestamp) + parseInt(random)) % 100;
    return `TKT${timestamp}${random}${checksum.toString().padStart(2, "0")}`;
  } catch (error) {
    console.error("Ticket number generation error:", error.message);
    return `TKT${Date.now()}${Math.floor(Math.random() * 1000)}`;
  }
}

// Purchase Ticket Function - Single ticket per event
exports.purchaseTicket = onCall(async (request) => {
  console.log("=== PURCHASE TICKET FUNCTION START ===");
  console.log("Auth object:", !!request.auth);
  console.log("Auth UID:", request.auth?.uid || "none");
  
  try {
    // Check authentication
    if (!request.auth) {
      console.log("No auth found in request.auth");
      throw new HttpsError("unauthenticated", "You must be signed in to purchase a ticket");
    }

    const userId = request.auth.uid;
    console.log("Authenticated user:", userId);

    // Extract and validate parameters
    const { eventId } = request.data;

    if (!eventId || typeof eventId !== 'string' || eventId.trim() === '') {
      throw new HttpsError("invalid-argument", "Valid event ID is required");
    }

    console.log(`Processing purchase for event ${eventId}`);

    // Execute transaction
    const result = await db.runTransaction(async (transaction) => {
      const eventRef = db.collection("events").doc(eventId);
      const eventDoc = await transaction.get(eventRef);

      if (!eventDoc.exists) {
        throw new HttpsError("not-found", "Event not found");
      }

      const event = eventDoc.data();

      // Check if user already has a ticket for this event
      const existingTicketQuery = await db.collection("tickets")
        .where("userId", "==", userId)
        .where("eventId", "==", eventId)
        .where("status", "==", "confirmed")
        .get();

      if (!existingTicketQuery.empty) {
        throw new HttpsError("failed-precondition", "You already have a ticket for this event");
      }

      const availableTickets = event.maxTickets - event.ticketsSold;

      if (availableTickets < 1) {
        throw new HttpsError("failed-precondition", "No tickets available for this event");
      }

      // Check if event date hasn't passed
      if (event.date && event.date.toDate() <= new Date()) {
        throw new HttpsError("failed-precondition", "Cannot purchase tickets for past events");
      }

      // Generate ticket data
      const ticketRef = db.collection("tickets").doc();
      const ticketId = ticketRef.id;
      const ticketNumber = generateTicketNumber();
      const totalPrice = event.price;
      const qrCodeData = generateQRCodeData(ticketId, eventId, userId, ticketNumber);

      // Create ticket document
      const ticketData = {
        eventId: eventId,
        eventName: event.name,
        eventDate: event.date,
        venue: event.venue,
        venueId: event.venueId,
        userId: userId,
        pricePerTicket: event.price,
        totalPrice: totalPrice,
        purchaseDate: new Date(),
        status: "confirmed",
        qrCode: qrCodeData,
        ticketNumber: ticketNumber,
        isUsed: false,
        createdAt: new Date()
      };

      // Add ticket to main collection
      transaction.set(ticketRef, ticketData);

      // Add ticket to user's subcollection
      const userTicketRef = db.collection("users").doc(userId).collection("tickets").doc(ticketId);
      transaction.set(userTicketRef, ticketData);

      // Update event ticket count
      transaction.update(eventRef, {
        ticketsSold: event.ticketsSold + 1
      });

      // Create transaction record
      const transactionRef = db.collection("transactions").doc();
      transaction.set(transactionRef, {
        type: "ticket_purchase",
        userId: userId,
        eventId: eventId,
        ticketId: ticketId,
        amount: totalPrice,
        timestamp: new Date(),
        status: "completed",
        ticketNumber: ticketNumber
      });

      return {
        success: true,
        ticketId: ticketId,
        totalPrice: totalPrice,
        qrCode: qrCodeData,
        ticketNumber: ticketNumber,
        message: "Ticket purchased successfully! Your QR code is ready for scanning.",
        eventName: event.name,
        venue: event.venue
      };
    });

    console.log("Purchase completed successfully:", result.ticketId);
    return result;

  } catch (error) {
    console.error("Purchase function error:", error.message);
    
    // Re-throw HttpsError as-is
    if (error instanceof HttpsError) {
      throw error;
    }
    
    // Wrap other errors
    throw new HttpsError("internal", `Purchase failed: ${error.message}`);
  }
});

// Check if user has ticket for event
exports.checkUserTicket = onCall(async (request) => {
  console.log("=== CHECK USER TICKET FUNCTION START ===");
  
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in to check tickets");
    }

    const userId = request.auth.uid;
    const { eventId } = request.data;

    if (!eventId || typeof eventId !== 'string' || eventId.trim() === '') {
      throw new HttpsError("invalid-argument", "Valid event ID is required");
    }

    console.log(`Checking ticket for user ${userId}, event ${eventId}`);

    const ticketQuery = await db.collection("tickets")
      .where("userId", "==", userId)
      .where("eventId", "==", eventId)
      .where("status", "==", "confirmed")
      .get();

    return {
      hasTicket: !ticketQuery.empty,
      ticketId: !ticketQuery.empty ? ticketQuery.docs[0].id : null
    };

  } catch (error) {
    console.error("Check ticket error:", error.message);
    
    if (error instanceof HttpsError) {
      throw error;
    }
    
    throw new HttpsError("internal", "Failed to check ticket: " + error.message);
  }
});

// Get User Tickets Function
exports.getUserTickets = onCall(async (request) => {
  console.log("=== GET USER TICKETS FUNCTION START ===");
  
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in to view tickets");
    }

    const userId = request.auth.uid;
    console.log("Getting tickets for user:", userId);

    const ticketsSnapshot = await db.collection("users")
      .doc(userId)
      .collection("tickets")
      .orderBy("purchaseDate", "desc")
      .get();

    const tickets = ticketsSnapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        ...data,
        purchaseDate: data.purchaseDate?.toDate?.()?.toISOString() || data.purchaseDate,
        eventDate: data.eventDate?.toDate?.()?.toISOString() || data.eventDate,
        qrCode: data.qrCode || generateQRCodeData(doc.id, data.eventId, userId, data.ticketNumber)
      };
    });

    console.log("Found tickets:", tickets.length);
    return { tickets };

  } catch (error) {
    console.error("Get tickets error:", error.message);
    
    if (error instanceof HttpsError) {
      throw error;
    }
    
    throw new HttpsError("internal", "Failed to fetch tickets: " + error.message);
  }
});

// Add this to your Cloud Functions index.js temporarily

// TEMPORARY SETUP FUNCTION - Remove after setting up first admin
exports.setupFirstAdmin = onCall(async (request) => {
  console.log("=== SETUP FIRST ADMIN FUNCTION START ===");
  
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const userId = request.auth.uid;
    const { adminEmail } = request.data;

    // Security check - only allow if no site admins exist yet
    const existingAdmins = await db.collection("admins")
      .where("role", "==", "siteAdmin")
      .where("active", "==", true)
      .get();

    if (!existingAdmins.empty) {
      throw new HttpsError("failed-precondition", "Site admin already exists. Use regular admin creation.");
    }

    // Verify the email matches the authenticated user
    const userRecord = await auth.getUser(userId);
    if (userRecord.email !== adminEmail) {
      throw new HttpsError("permission-denied", "Email must match your authenticated account");
    }

    // Set custom claims
    await auth.setCustomUserClaims(userId, {
      role: 'siteAdmin',
      active: true
    });

    // Create admin document
    await db.collection("admins").doc(userId).set({
      email: adminEmail,
      name: userRecord.displayName || "Site Administrator",
      role: "siteAdmin",
      venueId: null,
      active: true,
      createdAt: new Date(),
      createdBy: userId, // Self-created
      needsPasswordReset: false
    });

    console.log(`First site admin ${adminEmail} created successfully`);
    
    return {
      success: true,
      message: `Site admin ${adminEmail} created successfully! Please refresh the page.`,
      userId: userId
    };

  } catch (error) {
    console.error("Setup first admin error:", error.message);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", `Failed to setup admin: ${error.message}`);
  }
});

// Add this temporary debug function to your Cloud Functions

exports.debugAdmins = onCall(async (request) => {
  console.log("=== DEBUG ADMINS FUNCTION START ===");
  
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const userId = request.auth.uid;
    console.log("Debug request from user:", userId);

    // Check all admins in database
    const allAdmins = await db.collection("admins").get();
    console.log("Total admin documents:", allAdmins.size);

    const adminData = [];
    allAdmins.forEach(doc => {
      const data = doc.data();
      adminData.push({
        id: doc.id,
        email: data.email,
        role: data.role,
        active: data.active,
        createdAt: data.createdAt
      });
      console.log(`Admin found: ${doc.id} - ${data.email} - ${data.role} - Active: ${data.active}`);
    });

    // Check specifically for site admins
    const siteAdmins = await db.collection("admins")
      .where("role", "==", "siteAdmin")
      .where("active", "==", true)
      .get();

    console.log("Active site admins:", siteAdmins.size);

    // Check current user's custom claims
    let userClaims = null;
    try {
      const userRecord = await auth.getUser(userId);
      userClaims = userRecord.customClaims || {};
      console.log("User custom claims:", userClaims);
    } catch (error) {
      console.log("Error getting user claims:", error.message);
    }

    return {
      success: true,
      data: {
        totalAdmins: allAdmins.size,
        activeSiteAdmins: siteAdmins.size,
        allAdmins: adminData,
        currentUserClaims: userClaims,
        currentUserId: userId
      }
    };

  } catch (error) {
    console.error("Debug function error:", error.message);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", `Debug failed: ${error.message}`);
  }
});