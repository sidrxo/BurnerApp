const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

// Get instances only inside function calls, not at module level
function getDb() {
  return admin.firestore();
}

function getAuth() {
  return admin.auth();
}

// ============ PHASE 1: CREATE VENUES COLLECTION ============

exports.migrateCreateVenues = onCall(async (request) => {
  console.log("=== MIGRATE: CREATE VENUES ===");
  
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
    const venueMap = new Map();
    
    eventsSnap.forEach(doc => {
      const data = doc.data();
      const venueName = data.venue;
      
      if (venueName && typeof venueName === 'string') {
        const venueId = venueName
          .toLowerCase()
          .trim()
          .replace(/[^a-z0-9]/g, '_')
          .replace(/_+/g, '_')
          .replace(/^_|_$/g, '');
        
        if (!venueMap.has(venueId)) {
          venueMap.set(venueId, {
            id: venueId,
            name: venueName,
            events: []
          });
        }
        
        venueMap.get(venueId).events.push(doc.id);
      }
    });

    const batch = db.batch();
    const venuesCreated = [];
    
    venueMap.forEach((venueData, venueId) => {
      const venueRef = db.collection("venues").doc(venueId);
      
      batch.set(venueRef, {
        name: venueData.name,
        admins: [],
        subAdmins: [],
        active: true,
        eventCount: venueData.events.length,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        createdBy: request.auth.uid,
        migrated: true
      });
      
      venuesCreated.push({
        id: venueId,
        name: venueData.name,
        eventCount: venueData.events.length
      });
    });

    await batch.commit();
    
    return {
      success: true,
      message: `Successfully created ${venuesCreated.length} venues`,
      venues: venuesCreated
    };

  } catch (error) {
    console.error("Migration error:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", `Migration failed: ${error.message}`);
  }
});

// ============ PHASE 2: ADD VENUE IDS TO EVENTS ============

exports.migrateAddVenueIdsToEvents = onCall(async (request) => {
  console.log("=== MIGRATE: ADD VENUE IDS TO EVENTS ===");
  
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
    const venueNameToId = new Map();
    
    venuesSnap.forEach(doc => {
      const data = doc.data();
      venueNameToId.set(data.name, doc.id);
    });

    const eventsSnap = await db.collection("events").get();
    const updates = [];
    let updated = 0;
    let skipped = 0;
    let errors = [];

    for (const eventDoc of eventsSnap.docs) {
      const data = eventDoc.data();
      
      if (data.venueId) {
        skipped++;
        continue;
      }

      const venueName = data.venue;
      if (!venueName) {
        errors.push({
          eventId: eventDoc.id,
          error: "No venue name found"
        });
        continue;
      }

      const venueId = venueNameToId.get(venueName);
      if (!venueId) {
        errors.push({
          eventId: eventDoc.id,
          venueName: venueName,
          error: "Venue not found in venues collection"
        });
        continue;
      }

      updates.push({
        ref: eventDoc.ref,
        venueId: venueId
      });
      updated++;
    }

    const batchSize = 500;
    for (let i = 0; i < updates.length; i += batchSize) {
      const batch = db.batch();
      const batchUpdates = updates.slice(i, i + batchSize);
      
      batchUpdates.forEach(update => {
        batch.update(update.ref, {
          venueId: update.venueId,
          migratedVenueId: true,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
      });
      
      await batch.commit();
    }
    
    return {
      success: true,
      message: `Updated ${updated} events with venueId`,
      updated: updated,
      skipped: skipped,
      errors: errors.length > 0 ? errors : undefined
    };

  } catch (error) {
    console.error("Migration error:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", `Migration failed: ${error.message}`);
  }
});

// ============ PHASE 3: MIGRATE BOOKMARKS ============

exports.migrateBookmarksToRoot = onCall(async (request) => {
  console.log("=== MIGRATE: BOOKMARKS TO ROOT ===");
  
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
    
    let totalBookmarks = 0;
    let created = 0;
    let skipped = 0;

    for (const userDoc of usersSnap.docs) {
      const userId = userDoc.id;
      const bookmarksSnap = await userDoc.ref.collection("bookmarks").get();
      
      if (bookmarksSnap.empty) continue;

      totalBookmarks += bookmarksSnap.size;

      for (const bookmarkDoc of bookmarksSnap.docs) {
        const bookmarkData = bookmarkDoc.data();
        const eventId = bookmarkData.eventId || bookmarkDoc.id;
        
        const newBookmarkId = `${userId}_${eventId}`;
        const newBookmarkRef = db.collection("bookmarks").doc(newBookmarkId);
        
        const exists = await newBookmarkRef.get();
        if (exists.exists) {
          skipped++;
          continue;
        }

        await newBookmarkRef.set({
          userId: userId,
          eventId: eventId,
          bookmarkedAt: bookmarkData.bookmarkedAt || admin.firestore.FieldValue.serverTimestamp(),
          migrated: true
        });
        
        created++;
      }
    }
    
    return {
      success: true,
      message: `Migrated ${created} bookmarks to root collection`,
      totalFound: totalBookmarks,
      created: created,
      skipped: skipped
    };

  } catch (error) {
    console.error("Migration error:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", `Migration failed: ${error.message}`);
  }
});

// ============ VERIFICATION FUNCTIONS ============

exports.verifyMigrationStatus = onCall(async (request) => {
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const db = getDb();
    
    const [venuesSnap, eventsSnap, bookmarksSnap] = await Promise.all([
      db.collection("venues").get(),
      db.collection("events").get(),
      db.collection("bookmarks").get()
    ]);

    const eventsWithVenueId = eventsSnap.docs.filter(doc => doc.data().venueId).length;
    const eventsWithoutVenueId = eventsSnap.size - eventsWithVenueId;

    return {
      success: true,
      status: {
        venues: {
          total: venuesSnap.size,
          status: venuesSnap.size > 0 ? "✅ Migrated" : "❌ Not migrated"
        },
        events: {
          total: eventsSnap.size,
          withVenueId: eventsWithVenueId,
          withoutVenueId: eventsWithoutVenueId,
          status: eventsWithVenueId === eventsSnap.size ? "✅ All migrated" : `⚠️ ${eventsWithoutVenueId} events need migration`
        },
        bookmarks: {
          inRootCollection: bookmarksSnap.size,
          status: bookmarksSnap.size > 0 ? "✅ Migrated" : "❌ Not migrated"
        }
      }
    };

  } catch (error) {
    console.error("Verification error:", error);
    throw new HttpsError("internal", `Verification failed: ${error.message}`);
  }
});