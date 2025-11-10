const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { verifyScannerPermission } = require("../shared/permissions");
const { generateSecurityHash } = require("./ticketHelpers");

const db = getFirestore();

/**
 * Scan and validate a ticket QR code
 * Only callable by scanners with proper venue access
 */
exports.scanTicket = onCall({ region: "europe-west2" }, async (request) => {
  console.log("=== SCAN TICKET FUNCTION START ===");

  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const { ticketId, qrCodeData } = request.data;

    if (!ticketId) {
      throw new HttpsError("invalid-argument", "Ticket ID is required");
    }

    // Get ticket document
    const ticketRef = db.collection("tickets").doc(ticketId);
    const ticketDoc = await ticketRef.get();

    if (!ticketDoc.exists) {
      throw new HttpsError("not-found", "Ticket not found");
    }

    const ticket = ticketDoc.data();

    // Verify scanner has access to this venue
    await verifyScannerPermission(request.auth.uid, ticket.venueId);

    // Validate QR code data if provided
    if (qrCodeData) {
      try {
        const qrData = JSON.parse(qrCodeData);
        
        // Verify QR code matches ticket
        if (qrData.ticketId !== ticketId) {
          throw new HttpsError("invalid-argument", "QR code does not match ticket");
        }

        // Verify security hash
        const expectedHash = generateSecurityHash(
          qrData.ticketId,
          qrData.eventId,
          qrData.userId
        );

        if (qrData.hash !== expectedHash) {
          throw new HttpsError("permission-denied", "Invalid QR code signature");
        }
      } catch (parseError) {
        console.error("QR validation error:", parseError);
        throw new HttpsError("invalid-argument", "Invalid QR code format");
      }
    }

    // ✅ Check ticket status - ENHANCED with scanner details
    if (ticket.status === "used") {
      // Get scanner details who previously scanned this ticket
      let scannerName = "Unknown Scanner";
      let scannerEmail = ticket.scannedByEmail || null;
      
      if (ticket.scannedBy) {
        try {
          const scannerDoc = await db.collection("scanners").doc(ticket.scannedBy).get();
          if (scannerDoc.exists) {
            scannerName = scannerDoc.data().name || scannerEmail || "Unknown Scanner";
          }
        } catch (scannerError) {
          console.error("Error fetching scanner details:", scannerError);
        }
      }

      return {
        success: false,
        message: "Ticket already used",
        ticketStatus: "used",
        usedAt: ticket.usedAt?.toDate().toISOString(),
        scannedBy: ticket.scannedBy,
        scannedByName: scannerName,
        scannedByEmail: scannerEmail,
        ticket: {
          id: ticketId,
          eventName: ticket.eventName,
          venue: ticket.venue,
          userName: ticket.userName || "Unknown",
          ticketNumber: ticket.ticketNumber,
          status: ticket.status
        }
      };
    }

    if (ticket.status === "cancelled") {
      return {
        success: false,
        message: "Ticket has been cancelled",
        ticketStatus: "cancelled",
        ticket: {
          id: ticketId,
          eventName: ticket.eventName,
          status: ticket.status
        }
      };
    }

    // Check if event is today
    const eventDate = ticket.startTime?.toDate();
    const today = new Date();
    const isToday = eventDate && 
                   eventDate.toDateString() === today.toDateString();

    if (!isToday) {
      return {
        success: false,
        message: "Event is not scheduled for today",
        ticketStatus: "invalid_date",
        eventDate: eventDate?.toISOString(),
        ticket: {
          id: ticketId,
          eventName: ticket.eventName,
          startTime: ticket.startTime
        }
      };
    }

    // Mark ticket as used
    await ticketRef.update({
      status: "used",
      usedAt: FieldValue.serverTimestamp(),
      scannedBy: request.auth.uid,
      scannedByEmail: request.auth.token.email || null
    });

    console.log(`Ticket ${ticketId} scanned successfully by ${request.auth.uid}`);

    return {
      success: true,
      message: "Ticket validated successfully",
      ticketStatus: "confirmed",
      ticket: {
        id: ticketId,
        eventName: ticket.eventName,
        venue: ticket.venue,
        userName: ticket.userName || "Unknown",
        ticketNumber: ticket.ticketNumber,
        status: "used",
        scannedAt: new Date().toISOString()
      }
    };

  } catch (error) {
    console.error("Scan ticket error:", error.message);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", `Failed to scan ticket: ${error.message}`);
  }
});

/**
 * Get scan history for a scanner
 * Returns list of tickets scanned by this scanner
 */
exports.getScanHistory = onCall({ region: "europe-west2" }, async (request) => {
  console.log("=== GET SCAN HISTORY FUNCTION START ===");

  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    // Verify user is a scanner
    const scannerClaims = await verifyScannerPermission(request.auth.uid);

    const { limit = 50, startDate, endDate } = request.data;

    let query = db.collection("tickets")
      .where("scannedBy", "==", request.auth.uid)
      .orderBy("usedAt", "desc")
      .limit(limit);

    // Add date filters if provided
    if (startDate) {
      query = query.where("usedAt", ">=", new Date(startDate));
    }
    if (endDate) {
      query = query.where("usedAt", "<=", new Date(endDate));
    }

    const snapshot = await query.get();

    const scans = snapshot.docs.map(doc => {
      const data = doc.data();
      return {
        ticketId: doc.id,
        eventName: data.eventName,
        venue: data.venue,
        ticketNumber: data.ticketNumber,
        scannedAt: data.usedAt?.toDate().toISOString(),
        userName: data.userName || "Unknown"
      };
    });

    return {
      success: true,
      scans: scans,
      count: scans.length,
      scannerId: request.auth.uid
    };

  } catch (error) {
    console.error("Get scan history error:", error.message);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", `Failed to get scan history: ${error.message}`);
  }
});