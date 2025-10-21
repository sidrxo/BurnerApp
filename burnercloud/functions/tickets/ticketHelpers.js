const crypto = require("crypto");
const { FieldValue } = require("firebase-admin/firestore");

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

/**
 * Creates a ticket in a Firestore transaction with all necessary fields
 * This consolidates ticket creation logic used across multiple payment flows
 *
 * @param {FirebaseFirestore.Transaction} transaction - Firestore transaction
 * @param {Object} params - Ticket creation parameters
 * @param {FirebaseFirestore.DocumentReference} params.ticketRef - Reference to ticket document
 * @param {FirebaseFirestore.DocumentReference} params.eventRef - Reference to event document
 * @param {Object} params.event - Event data object
 * @param {string} params.userId - User's Firebase UID
 * @param {string} [params.paymentIntentId] - Stripe payment intent ID (optional)
 * @param {Object} [params.paymentMethodDetails] - Payment method details from Stripe (optional)
 * @param {string} [params.customerEmail] - Customer email (optional)
 * @returns {Object} Created ticket data including ticketId, ticketNumber, qrCodeData
 */
function createTicketInTransaction(transaction, {
  ticketRef,
  eventRef,
  event,
  userId,
  paymentIntentId = null,
  paymentMethodDetails = null,
  customerEmail = null
}) {
  const ticketId = ticketRef.id;
  const ticketNumber = generateTicketNumber();
  const qrCodeData = generateQRCodeData(ticketId, event.id || eventRef.id, userId, ticketNumber);

  // Build base ticket data
  const ticketData = {
    eventId: event.id || eventRef.id,
    userId,
    ticketNumber,
    eventName: event.name,
    venue: event.venue,
    startTime: event.startTime,
    totalPrice: event.price,
    purchaseDate: FieldValue.serverTimestamp(),
    status: "confirmed",
    qrCode: qrCodeData,
    venueId: event.venueId || null,
  };

  // Add payment-related fields if provided
  if (paymentIntentId) {
    ticketData.paymentIntentId = paymentIntentId;
  }

  // Add payment method metadata if provided
  if (paymentMethodDetails) {
    ticketData.metadata = {
      paymentMethod: paymentMethodDetails.wallet || paymentMethodDetails.type || "card",
      ...paymentMethodDetails
    };

    if (customerEmail) {
      ticketData.metadata.customerEmail = customerEmail;
    }
  } else if (customerEmail) {
    ticketData.metadata = { customerEmail };
  }

  // Add payment method ID if available
  if (paymentMethodDetails?.id) {
    ticketData.paymentMethodId = paymentMethodDetails.id;
  }

  // Create ticket and update event in transaction
  transaction.set(ticketRef, ticketData);
  transaction.update(eventRef, {
    ticketsSold: event.ticketsSold + 1,
    updatedAt: FieldValue.serverTimestamp()
  });

  return {
    ticketId,
    ticketNumber,
    qrCodeData,
    ticketData
  };
}

module.exports = {
  generateQRCodeData,
  generateSecurityHash,
  generateTicketNumber,
  createTicketInTransaction
};