const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");

const db = getFirestore();

// Stripe secret key
const stripeSecretKey = defineSecret("sk_test_51SKOqrFxXnVDuRLXGQqJwOPXP43HETuBD6Ydwx4fCZ4kHyTLLz2RYsTyQuw8BW6mVkBaBkuEu8MDHYHiUx3mzQCB00G55Zeofz");

// Initialize Stripe
const getStripe = () => require("stripe")(stripeSecretKey.value());

// -------------------------
// Create Payment Intent
// -------------------------
exports.createPaymentIntent = onCall(
  { secrets: [stripeSecretKey] },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Authentication required");

    const userId = request.auth.uid;
    const { eventId } = request.data;
    if (!eventId) throw new HttpsError("invalid-argument", "Event ID required");

    const eventDoc = await db.collection("events").doc(eventId).get();
    if (!eventDoc.exists) throw new HttpsError("not-found", "Event not found");

    const event = eventDoc.data();
    if (event.maxTickets - event.ticketsSold < 1)
      throw new HttpsError("failed-precondition", "No tickets available");

    // Prevent duplicate tickets
    const existingTicket = await db.collection("tickets")
      .where("userId", "==", userId)
      .where("eventId", "==", eventId)
      .where("status", "==", "confirmed")
      .get();
    if (!existingTicket.empty)
      throw new HttpsError("failed-precondition", "You already have a ticket");

    const stripe = getStripe();

    // Get or create customer
    const userDoc = await db.collection("users").doc(userId).get();
    let customerId = userDoc.data()?.stripeCustomerId;
    if (!customerId) {
      const customer = await stripe.customers.create({
        email: userDoc.data()?.email || request.auth.token.email,
        metadata: { firebaseUID: userId }
      });
      customerId = customer.id;
      await db.collection("users").doc(userId).update({ stripeCustomerId: customerId });
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(event.price * 100),
      currency: "gbp",
      customer: customerId,
      metadata: { eventId, userId, eventName: event.name },
      automatic_payment_methods: { enabled: true }
    });

    await db.collection("pendingPayments").doc(paymentIntent.id).set({
      userId,
      eventId,
      amount: event.price,
      status: "pending",
      createdAt: FieldValue.serverTimestamp()
    });

    return {
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
      amount: event.price
    };
  }
);

// -------------------------
// Confirm Apple Pay Payment
// -------------------------
exports.confirmApplePayPayment = onCall(
  { secrets: [stripeSecretKey] },
  async (request) => {
    const { paymentIntentId, paymentToken } = request.data;
    if (!paymentIntentId || !paymentToken)
      throw new HttpsError("invalid-argument", "Missing paymentIntentId or paymentToken");

    const stripe = getStripe();

    // Confirm PaymentIntent using Apple Pay token
    const paymentIntent = await stripe.paymentIntents.confirm(paymentIntentId, {
      payment_method: paymentToken
    });

    return { status: paymentIntent.status };
  }
);

// -------------------------
// Confirm Purchase (create ticket)
// -------------------------
exports.confirmPurchase = onCall(
  { secrets: [stripeSecretKey] },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Authentication required");

    const userId = request.auth.uid;
    const { paymentIntentId } = request.data;
    if (!paymentIntentId) throw new HttpsError("invalid-argument", "Payment intent ID required");

    const stripe = getStripe();
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);

    if (paymentIntent.status !== "succeeded") {
      throw new HttpsError("failed-precondition", "Payment not completed");
    }

    const pendingPaymentDoc = await db.collection("pendingPayments").doc(paymentIntentId).get();
    if (!pendingPaymentDoc.exists) throw new HttpsError("not-found", "Payment record not found");

    const pendingPayment = pendingPaymentDoc.data();
    const eventId = pendingPayment.eventId;

    return await db.runTransaction(async (transaction) => {
      const eventRef = db.collection("events").doc(eventId);
      const eventDoc = await transaction.get(eventRef);
      if (!eventDoc.exists) throw new HttpsError("not-found", "Event not found");

      const event = eventDoc.data();
      if (event.maxTickets - event.ticketsSold < 1) {
        await stripe.refunds.create({ payment_intent: paymentIntentId });
        throw new HttpsError("failed-precondition", "Event sold out");
      }

      const { generateQRCodeData, generateTicketNumber } = require("./ticketHelpers");
      const ticketRef = db.collection("tickets").doc();
      const ticketId = ticketRef.id;
      const ticketNumber = generateTicketNumber();
      const qrCodeData = generateQRCodeData(ticketId, eventId, userId, ticketNumber);

      const ticketData = {
        eventId,
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
        paymentIntentId
      };

      transaction.set(ticketRef, ticketData);
      transaction.update(eventRef, { ticketsSold: event.ticketsSold + 1 });
      transaction.update(pendingPaymentDoc.ref, { status: "completed", ticketId, completedAt: FieldValue.serverTimestamp() });

      return {
        success: true,
        ticketId,
        message: "Ticket purchased successfully!"
      };
    });
  }
);
