const { HttpsError } = require("firebase-functions/v2/https");
const { getFirestore } = require("firebase-admin/firestore");

const db = getFirestore();

/**
 * Validates that a user doesn't already have a ticket for an event
 * and that tickets are still available
 *
 * @param {string} userId - The user's Firebase UID
 * @param {string} eventId - The event document ID
 * @param {FirebaseFirestore.Transaction} transaction - Optional transaction for atomic operations
 * @returns {Promise<Object>} The event data if validation passes
 * @throws {HttpsError} If user already has ticket or event is sold out
 */
async function validateTicketAvailability(userId, eventId, transaction = null) {
  // Check for existing ticket
  const existingTicket = await db.collection("tickets")
    .where("userId", "==", userId)
    .where("eventId", "==", eventId)
    .where("status", "==", "confirmed")
    .limit(1)
    .get();

  if (!existingTicket.empty) {
    throw new HttpsError(
      "failed-precondition",
      "You already have a ticket for this event"
    );
  }

  // Get event data
  const eventRef = db.collection("events").doc(eventId);
  const eventDoc = transaction
    ? await transaction.get(eventRef)
    : await eventRef.get();

  if (!eventDoc.exists) {
    throw new HttpsError("not-found", "Event not found");
  }

  const event = eventDoc.data();

  // Check ticket availability
  if (event.maxTickets - event.ticketsSold < 1) {
    throw new HttpsError(
      "failed-precondition",
      "No tickets available for this event"
    );
  }

  return { event, eventRef, eventDoc };
}

/**
 * Initiates a refund for a Stripe payment
 *
 * @param {Object} stripe - Initialized Stripe client
 * @param {string} paymentIntentId - The payment intent ID to refund
 * @param {string} reason - Reason for refund (e.g., 'duplicate', 'requested_by_customer')
 * @returns {Promise<Object>} The refund object from Stripe
 */
async function initiateRefund(stripe, paymentIntentId, reason = 'requested_by_customer') {
  try {
    const refund = await stripe.refunds.create({
      payment_intent: paymentIntentId,
      reason: reason
    });

    console.log(`Refund initiated for ${paymentIntentId}: ${reason}`);
    return refund;
  } catch (error) {
    console.error(`Error initiating refund for ${paymentIntentId}:`, error);
    throw error;
  }
}

module.exports = {
  validateTicketAvailability,
  initiateRefund
};
