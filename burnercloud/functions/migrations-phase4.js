const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

function getDb() {
  return admin.firestore();
}

function getAuth() {
  return admin.auth();
}

// ============ PHASE 4A: ENHANCE VENUES COLLECTION ============

exports.migrateEnhanceVenues = onCall(async (request) => {
  console.log("=== MIGRATE: ENHANCE VENUES ===");
  
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const db = getDb();
    const auth = getAuth();
    
    const userRecord = await auth.getUser(request.auth.uid);
    if (userRecord.customClaims?.role !== 'siteAdmin') {
      throw new HttpsError("permission-denied", "Only site admins can run migrations");
    }

    const venuesSnap = await db.collection("venues").get();
    const batch = db.batch();
    let updated = 0;

    venuesSnap.forEach(doc => {
      const data = doc.data();
      
      // Add missing fields if they don't exist
      const updates = {
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };

      if (!data.address) updates.address = "";
      if (!data.city) updates.city = "";
      if (!data.capacity) updates.capacity = 0;
      if (!data.imageUrl) updates.imageUrl = null;
      if (!data.coordinates) updates.coordinates = null;
      if (!data.contactEmail) updates.contactEmail = "";
      if (!data.website) updates.website = "";
      
      batch.update(doc.ref, updates);
      updated++;
    });

    await batch.commit();
    
    return {
      success: true,
      message: `Enhanced ${updated} venues with additional fields`,
      updated: updated
    };

  } catch (error) {
    console.error("Migration error:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", `Migration failed: ${error.message}`);
  }
});

// ============ PHASE 4B: ENHANCE EVENTS COLLECTION ============

exports.migrateEnhanceEvents = onCall(async (request) => {
  console.log("=== MIGRATE: ENHANCE EVENTS ===");
  
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const db = getDb();
    const auth = getAuth();
    
    const userRecord = await auth.getUser(request.auth.uid);
    if (userRecord.customClaims?.role !== 'siteAdmin') {
      throw new HttpsError("permission-denied", "Only site admins can run migrations");
    }

    const eventsSnap = await db.collection("events").get();
    let updated = 0;
    let skipped = 0;

    const batchSize = 500;
    const batches = [];
    let currentBatch = db.batch();
    let operationCount = 0;

    for (const eventDoc of eventsSnap.docs) {
      const data = eventDoc.data();
      
      // Skip if already migrated
      if (data.migratedPhase4) {
        skipped++;
        continue;
      }

      const updates = {
        migratedPhase4: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };

      // Add status field (derive from current data)
      if (!data.status) {
        const now = new Date();
        const eventDate = data.date?.toDate ? data.date.toDate() : new Date(data.date);
        const isSoldOut = (data.ticketsSold || 0) >= (data.maxTickets || 0);
        const isPast = eventDate < now;
        
        if (isPast) {
          updates.status = "past";
        } else if (isSoldOut) {
          updates.status = "soldOut";
        } else {
          updates.status = "active";
        }
      }

      // Add endTime (default to 4 hours after start)
      if (!data.endTime && data.date) {
        const startDate = data.date.toDate ? data.date.toDate() : new Date(data.date);
        const endDate = new Date(startDate.getTime() + (4 * 60 * 60 * 1000)); // +4 hours
        updates.endTime = admin.firestore.Timestamp.fromDate(endDate);
      }

      // Rename date to startTime for consistency
      if (data.date && !data.startTime) {
        updates.startTime = data.date;
      }

      // Add missing fields
      if (!data.category) updates.category = "general";
      if (!data.tags) updates.tags = [];
      if (!data.organizerId) updates.organizerId = data.createdBy || null;

      currentBatch.update(eventDoc.ref, updates);
      operationCount++;
      updated++;

      // Commit batch if we hit the limit
      if (operationCount >= batchSize) {
        batches.push(currentBatch.commit());
        currentBatch = db.batch();
        operationCount = 0;
      }
    }

    // Commit remaining operations
    if (operationCount > 0) {
      batches.push(currentBatch.commit());
    }

    await Promise.all(batches);
    
    return {
      success: true,
      message: `Enhanced ${updated} events, skipped ${skipped}`,
      updated: updated,
      skipped: skipped
    };

  } catch (error) {
    console.error("Migration error:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", `Migration failed: ${error.message}`);
  }
});

// ============ PHASE 4C: ENHANCE TICKETS COLLECTION ============

exports.migrateEnhanceTickets = onCall(async (request) => {
  console.log("=== MIGRATE: ENHANCE TICKETS ===");
  
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const db = getDb();
    const auth = getAuth();
    
    const userRecord = await auth.getUser(request.auth.uid);
    if (userRecord.customClaims?.role !== 'siteAdmin') {
      throw new HttpsError("permission-denied", "Only site admins can run migrations");
    }

    // Get all tickets from collectionGroup
    const ticketsSnap = await db.collectionGroup("tickets").get();
    let updated = 0;
    let skipped = 0;

    const batchSize = 500;
    const batches = [];
    let currentBatch = db.batch();
    let operationCount = 0;

    for (const ticketDoc of ticketsSnap.docs) {
      const data = ticketDoc.data();
      
      // Skip if already migrated
      if (data.migratedPhase4) {
        skipped++;
        continue;
      }

      const updates = {
        migratedPhase4: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };

      // Map old field names to new ones
      if (data.pricePerTicket && !data.purchasePrice) {
        updates.purchasePrice = data.pricePerTicket;
      }

      // Ensure status field exists
      if (!data.status) {
        if (data.isUsed) {
          updates.status = "used";
        } else {
          updates.status = "confirmed";
        }
      }

      // Add missing fields
      if (!data.ticketNumber) {
        // Generate ticket number if missing
        const timestamp = Date.now().toString().slice(-6);
        const random = Math.floor(Math.random() * 1000).toString().padStart(3, "0");
        updates.ticketNumber = `TKT-${timestamp}-${random}`;
      }

      if (!data.qrCodeSignature) updates.qrCodeSignature = null;
      if (!data.scannedBy) updates.scannedBy = null;
      if (!data.cancelledAt) updates.cancelledAt = null;
      if (!data.cancelReason) updates.cancelReason = null;
      if (!data.refundedAt) updates.refundedAt = null;
      if (!data.refundAmount) updates.refundAmount = null;
      if (!data.transferredFrom) updates.transferredFrom = null;
      if (!data.transferredAt) updates.transferredAt = null;

      currentBatch.update(ticketDoc.ref, updates);
      operationCount++;
      updated++;

      if (operationCount >= batchSize) {
        batches.push(currentBatch.commit());
        currentBatch = db.batch();
        operationCount = 0;
      }
    }

    if (operationCount > 0) {
      batches.push(currentBatch.commit());
    }

    await Promise.all(batches);
    
    return {
      success: true,
      message: `Enhanced ${updated} tickets, skipped ${skipped}`,
      updated: updated,
      skipped: skipped
    };

  } catch (error) {
    console.error("Migration error:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", `Migration failed: ${error.message}`);
  }
});

// ============ PHASE 4D: ENHANCE USERS COLLECTION ============

exports.migrateEnhanceUsers = onCall(async (request) => {
  console.log("=== MIGRATE: ENHANCE USERS ===");
  
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const db = getDb();
    const auth = getAuth();
    
    const userRecord = await auth.getUser(request.auth.uid);
    if (userRecord.customClaims?.role !== 'siteAdmin') {
      throw new HttpsError("permission-denied", "Only site admins can run migrations");
    }

    const usersSnap = await db.collection("users").get();
    const batch = db.batch();
    let updated = 0;

    usersSnap.forEach(doc => {
      const data = doc.data();
      
      const updates = {
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };

      // Add missing fields
      if (!data.phoneNumber) updates.phoneNumber = null;
      if (!data.stripeCustomerId) updates.stripeCustomerId = null;
      if (!data.profileImageUrl) updates.profileImageUrl = null;
      if (!data.preferences) {
        updates.preferences = {
          notifications: true,
          emailMarketing: false,
          pushNotifications: true
        };
      }

      batch.update(doc.ref, updates);
      updated++;
    });

    await batch.commit();
    
    return {
      success: true,
      message: `Enhanced ${updated} users with additional fields`,
      updated: updated
    };

  } catch (error) {
    console.error("Migration error:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", `Migration failed: ${error.message}`);
  }
});

// ============ PHASE 4E: CREATE EVENT STATS COLLECTION ============

exports.migrateCreateEventStats = onCall(async (request) => {
  console.log("=== MIGRATE: CREATE EVENT STATS ===");
  
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const db = getDb();
    const auth = getAuth();
    
    const userRecord = await auth.getUser(request.auth.uid);
    if (userRecord.customClaims?.role !== 'siteAdmin') {
      throw new HttpsError("permission-denied", "Only site admins can run migrations");
    }

    const eventsSnap = await db.collection("events").get();
    const batch = db.batch();
    let created = 0;

    for (const eventDoc of eventsSnap.docs) {
      const eventData = eventDoc.data();
      const eventId = eventDoc.id;

      // Count bookmarks for this event
      const bookmarksSnap = await db.collection("bookmarks")
        .where("eventId", "==", eventId)
        .get();

      // Get tickets for this event
      const ticketsSnap = await db.collectionGroup("tickets")
        .where("eventId", "==", eventId)
        .get();

      const totalRevenue = ticketsSnap.docs.reduce((sum, doc) => {
        const price = doc.data().purchasePrice || doc.data().pricePerTicket || 0;
        return sum + price;
      }, 0);

      // Count tickets sold today
      const todayStart = new Date();
      todayStart.setHours(0, 0, 0, 0);
      
      const ticketsSoldToday = ticketsSnap.docs.filter(doc => {
        const purchaseDate = doc.data().purchaseDate?.toDate();
        return purchaseDate && purchaseDate >= todayStart;
      }).length;

      // Create event stats document
      const statsRef = db.collection("eventStats").doc(eventId);
      batch.set(statsRef, {
        totalBookmarks: bookmarksSnap.size,
        totalTicketsSold: ticketsSnap.size,
        totalRevenue: totalRevenue,
        ticketsSoldToday: ticketsSoldToday,
        trendingScore: 0, // Can be calculated later based on your algorithm
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
      });

      created++;
    }

    await batch.commit();
    
    return {
      success: true,
      message: `Created event stats for ${created} events`,
      created: created
    };

  } catch (error) {
    console.error("Migration error:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", `Migration failed: ${error.message}`);
  }
});

// ============ VERIFICATION ============

exports.verifyPhase4Status = onCall(async (request) => {
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const db = getDb();
    
    const [venuesSnap, eventsSnap, ticketsSnap, usersSnap, eventStatsSnap] = await Promise.all([
      db.collection("venues").get(),
      db.collection("events").get(),
      db.collectionGroup("tickets").get(),
      db.collection("users").get(),
      db.collection("eventStats").get()
    ]);

    // Check which documents have been migrated
    const venuesEnhanced = venuesSnap.docs.filter(doc => doc.data().address !== undefined).length;
    const eventsEnhanced = eventsSnap.docs.filter(doc => doc.data().migratedPhase4).length;
    const ticketsEnhanced = ticketsSnap.docs.filter(doc => doc.data().migratedPhase4).length;
    const usersEnhanced = usersSnap.docs.filter(doc => doc.data().preferences !== undefined).length;

    return {
      success: true,
      status: {
        venues: {
          total: venuesSnap.size,
          enhanced: venuesEnhanced,
          status: venuesEnhanced === venuesSnap.size ? "✅ All enhanced" : `⚠️ ${venuesSnap.size - venuesEnhanced} need enhancement`
        },
        events: {
          total: eventsSnap.size,
          enhanced: eventsEnhanced,
          status: eventsEnhanced === eventsSnap.size ? "✅ All enhanced" : `⚠️ ${eventsSnap.size - eventsEnhanced} need enhancement`
        },
        tickets: {
          total: ticketsSnap.size,
          enhanced: ticketsEnhanced,
          status: ticketsEnhanced === ticketsSnap.size ? "✅ All enhanced" : `⚠️ ${ticketsSnap.size - ticketsEnhanced} need enhancement`
        },
        users: {
          total: usersSnap.size,
          enhanced: usersEnhanced,
          status: usersEnhanced === usersSnap.size ? "✅ All enhanced" : `⚠️ ${usersSnap.size - usersEnhanced} need enhancement`
        },
        eventStats: {
          total: eventStatsSnap.size,
          status: eventStatsSnap.size > 0 ? "✅ Created" : "❌ Not created"
        }
      }
    };

  } catch (error) {
    console.error("Verification error:", error);
    throw new HttpsError("internal", `Verification failed: ${error.message}`);
  }
});

module.exports = {
  migrateEnhanceVenues: exports.migrateEnhanceVenues,
  migrateEnhanceEvents: exports.migrateEnhanceEvents,
  migrateEnhanceTickets: exports.migrateEnhanceTickets,
  migrateEnhanceUsers: exports.migrateEnhanceUsers,
  migrateCreateEventStats: exports.migrateCreateEventStats,
  verifyPhase4Status: exports.verifyPhase4Status
};