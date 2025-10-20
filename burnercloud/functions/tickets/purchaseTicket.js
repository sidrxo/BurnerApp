const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { generateQRCodeData, generateTicketNumber } = require("./ticketHelpers");

const db = getFirestore();

exports.purchaseTicket = onCall(async (request) => {
  console.log("=== PURCHASE TICKET FUNCTION START ===");
  
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in to purchase a ticket");
    }

    const userId = request.auth.uid;
    const { eventId } = request.data;

    if (!eventId || typeof eventId !== 'string' || eventId.trim() === '') {
      throw new HttpsError("invalid-argument", "Valid event ID is required");
    }

    console.log(`Processing purchase for event ${eventId}`);

    const result = await db.runTransaction(async (transaction) => {
      const eventRef = db.collection("events").doc(eventId);
      const eventDoc = await transaction.get(eventRef);

      if (!eventDoc.exists) {
        throw new HttpsError("not-found", "Event not found");
      }

      const event = eventDoc.data();

      // Check if user already has a ticket
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
      const eventDate = event.startTime || event.date;
      if (eventDate && eventDate.toDate() <= new Date()) {
        throw new HttpsError("failed-precondition", "Cannot purchase tickets for past events");
      }

      const ticketRef = db.collection("tickets").doc();
      const ticketId = ticketRef.id;
      const ticketNumber = generateTicketNumber();
      const qrCodeData = generateQRCodeData(ticketId, eventId, userId, ticketNumber);

      // ✅ STREAMLINED TICKET DATA
      const ticketData = {
        // Identity
        eventId: eventId,
        userId: userId,
        ticketNumber: ticketNumber,
        
        // Event info (for fallback when event document unavailable)
        eventName: event.name,
        venue: event.venue,
        startTime: event.startTime,  // Already a Firestore Timestamp
        
        // Purchase info
        totalPrice: event.price,
        purchaseDate: FieldValue.serverTimestamp(),  // ✅ Use serverTimestamp for consistency
        
        // Status & QR
        status: "confirmed",
        qrCode: qrCodeData,
        
        // Optional metadata
        venueId: event.venueId || null
      };

      // Add ticket to main collection
      transaction.set(ticketRef, ticketData);

      // Update event ticket count atomically
      transaction.update(eventRef, {
        ticketsSold: event.ticketsSold + 1
      });

      return {
        success: true,
        ticketId: ticketId,
        totalPrice: event.price,
        qrCode: qrCodeData,
        ticketNumber: ticketNumber,
        message: "Ticket purchased successfully!",
        eventName: event.name
      };
    });

    console.log("Purchase completed successfully:", result.ticketId);
    return result;

  } catch (error) {
    console.error("Purchase function error:", error.message);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", `Purchase failed: ${error.message}`);
  }
});