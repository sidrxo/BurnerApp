const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore } = require("firebase-admin/firestore");
const { generateQRCodeData } = require("./ticketHelpers");

const db = getFirestore();

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
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Failed to check ticket: " + error.message);
  }
});

exports.getUserTickets = onCall(async (request) => {
  console.log("=== GET USER TICKETS FUNCTION START ===");
  
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in to view tickets");
    }

    const userId = request.auth.uid;

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
        qrCode: data.qrCode || generateQRCodeData(doc.id, data.eventId, userId, data.ticketNumber)
      };
    });

    return { tickets };

  } catch (error) {
    console.error("Get tickets error:", error.message);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Failed to fetch tickets: " + error.message);
  }
});