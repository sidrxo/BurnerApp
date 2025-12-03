const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");

const db = getFirestore();

exports.transferTicket = onCall({ region: "europe-west2" }, async (request) => {
  console.log("=== TRANSFER TICKET FUNCTION START ===");

  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in to transfer tickets");
    }

    const userId = request.auth.uid;
    const { ticketId, recipientEmail } = request.data;

    // Validate inputs
    if (!ticketId || typeof ticketId !== 'string' || ticketId.trim() === '') {
      throw new HttpsError("invalid-argument", "Valid ticket ID is required");
    }

    if (!recipientEmail || typeof recipientEmail !== 'string' || recipientEmail.trim() === '') {
      throw new HttpsError("invalid-argument", "Valid recipient email is required");
    }

    const normalizedEmail = recipientEmail.toLowerCase().trim();

    // Verify ticket exists and belongs to user
    const ticketDoc = await db.collection("tickets").doc(ticketId).get();

    if (!ticketDoc.exists) {
      throw new HttpsError("not-found", "Ticket not found");
    }

    const ticketData = ticketDoc.data();

    // Check ownership
    if (ticketData.userId !== userId) {
      throw new HttpsError("permission-denied", "You don't own this ticket");
    }

    // Check ticket status
    if (ticketData.status !== "confirmed") {
      throw new HttpsError("failed-precondition", `Cannot transfer ticket with status: ${ticketData.status}`);
    }

    // Check if ticket has already been used
    if (ticketData.usedAt) {
      throw new HttpsError("failed-precondition", "Cannot transfer a used ticket");
    }

    // Find recipient by email
    let recipientUser;
    try {
      recipientUser = await getAuth().getUserByEmail(normalizedEmail);
    } catch (error) {
      if (error.code === 'auth/user-not-found') {
        throw new HttpsError("not-found", "No user found with that email address. The recipient must have a Burner account.");
      }
      throw error;
    }

    const recipientUserId = recipientUser.uid;

    // Prevent transferring to yourself
    if (recipientUserId === userId) {
      throw new HttpsError("invalid-argument", "Cannot transfer ticket to yourself");
    }

    // Check if recipient already has a ticket for this event
    const eventId = ticketData.eventId;
    const recipientTicketsSnapshot = await db.collection("tickets")
      .where("eventId", "==", eventId)
      .where("userId", "==", recipientUserId)
      .where("status", "==", "confirmed")
      .get();

    if (!recipientTicketsSnapshot.empty) {
      throw new HttpsError("already-exists", "This user already has a ticket for this event");
    }

    // Update ticket with new owner
    await ticketDoc.ref.update({
      userId: recipientUserId,
      transferredFrom: userId,
      transferredAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp()
    });

    console.log(`Ticket ${ticketId} transferred from ${userId} to ${recipientUserId}`);

    // Get sender's name for notification
    let senderName = "A user";
    try {
      const senderUser = await getAuth().getUser(userId);
      senderName = senderUser.displayName || senderUser.email || "A user";
    } catch (error) {
      console.warn("Could not get sender name:", error.message);
    }

    return {
      success: true,
      message: `Ticket successfully transferred to ${normalizedEmail}`,
      recipientName: recipientUser.displayName || normalizedEmail,
      senderName: senderName
    };

  } catch (error) {
    console.error("Transfer ticket error:", error.message);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Failed to transfer ticket: " + error.message);
  }
});
