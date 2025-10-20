const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = getFirestore();

// Stripe configuration
const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");
const getStripe = () => require("stripe")(stripeSecretKey.value());

// Logging utility
const logger = {
  info: (message, data = {}) => {
    console.log(JSON.stringify({
      timestamp: new Date().toISOString(),
      level: 'INFO',
      message,
      ...data
    }));
  },
  error: (message, error, data = {}) => {
    console.error(JSON.stringify({
      timestamp: new Date().toISOString(),
      level: 'ERROR',
      message,
      error: error.message,
      stack: error.stack,
      ...data
    }));
  }
};

// -------------------------
// Create Payment Intent
// -------------------------
exports.createPaymentIntent = onCall(
  { secrets: [stripeSecretKey] },
  async (request) => {
    try {
      if (!request.auth) {
        throw new HttpsError("unauthenticated", "Authentication required");
      }

      const userId = request.auth.uid;
      const { eventId } = request.data;

      if (!eventId) {
        throw new HttpsError("invalid-argument", "Event ID required");
      }

      logger.info('Creating payment intent', { userId, eventId });

      // Get event details
      const eventDoc = await db.collection("events").doc(eventId).get();
      if (!eventDoc.exists) {
        throw new HttpsError("not-found", "Event not found");
      }

      const event = eventDoc.data();

      // Check ticket availability
      if (event.maxTickets - event.ticketsSold < 1) {
        throw new HttpsError("failed-precondition", "No tickets available");
      }

      // Check for existing ticket
      const existingTicket = await db.collection("tickets")
        .where("userId", "==", userId)
        .where("eventId", "==", eventId)
        .where("status", "==", "confirmed")
        .limit(1)
        .get();

      if (!existingTicket.empty) {
        throw new HttpsError("failed-precondition", "You already have a ticket for this event");
      }

      const stripe = getStripe();

      // Get or create customer
      const userDoc = await db.collection("users").doc(userId).get();
      let customerId = userDoc.data()?.stripeCustomerId;

      if (!customerId) {
        const customer = await stripe.customers.create({
          email: userDoc.data()?.email || request.auth.token.email,
          metadata: {
            firebaseUID: userId,
            createdAt: new Date().toISOString()
          }
        });
        customerId = customer.id;
        await db.collection("users").doc(userId).update({
          stripeCustomerId: customerId,
          updatedAt: FieldValue.serverTimestamp()
        });
      }

      // Create payment intent
      const paymentIntent = await stripe.paymentIntents.create({
        amount: Math.round(event.price * 100),
        currency: "gbp",
        customer: customerId,
        metadata: {
          eventId,
          userId,
          eventName: event.name,
          createdAt: new Date().toISOString()
        },
        automatic_payment_methods: {
          enabled: true,
          allow_redirects: "never"
        },
        payment_method_types: ['card', 'apple_pay'],
        capture_method: "automatic",
        setup_future_usage: null,
        statement_descriptor: "BURNER TICKET",
        statement_descriptor_suffix: event.name.substring(0, 15)
      });

      // Record pending payment
      await db.collection("pendingPayments").doc(paymentIntent.id).set({
        userId,
        eventId,
        amount: event.price,
        status: "pending",
        createdAt: FieldValue.serverTimestamp(),
        metadata: {
          eventName: event.name,
          customerEmail: request.auth.token.email,
          customerId: customerId
        }
      });

      logger.info('Payment intent created', {
        paymentIntentId: paymentIntent.id,
        userId,
        eventId
      });

      return {
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
        amount: event.price
      };

    } catch (error) {
      logger.error('Error creating payment intent', error);
      throw new HttpsError(
        error.code || "internal",
        error.message || "Error creating payment intent"
      );
    }
  }
);

// -------------------------
// Confirm Apple Pay Payment
// -------------------------
exports.confirmApplePayPayment = onCall(
  { secrets: [stripeSecretKey] },
  async (request) => {
    try {
      if (!request.auth) {
        throw new HttpsError("unauthenticated", "Authentication required");
      }

      const { paymentIntentId } = request.data;
      if (!paymentIntentId) {
        throw new HttpsError("invalid-argument", "Missing paymentIntentId");
      }

      logger.info('Confirming Apple Pay payment', { paymentIntentId });

      const stripe = getStripe();

      try {
        // Confirm payment intent with Apple Pay
        const paymentIntent = await stripe.paymentIntents.confirm(paymentIntentId, {
          payment_method: 'apple_pay'
        });

        logger.info('Payment confirmed', {
          paymentIntentId,
          status: paymentIntent.status
        });

        return {
          status: paymentIntent.status
        };

      } catch (stripeError) {
        logger.error('Stripe error', stripeError);
        throw new HttpsError("internal", `Payment processing error: ${stripeError.message}`);
      }

    } catch (error) {
      logger.error('Error confirming Apple Pay payment', error);
      throw new HttpsError(
        error.code || "internal",
        error.message || "Error confirming payment"
      );
    }
  }
);

// -------------------------
// Confirm Purchase (create ticket)
// -------------------------
exports.confirmPurchase = onCall(
  { secrets: [stripeSecretKey] },
  async (request) => {
    try {
      if (!request.auth) {
        throw new HttpsError("unauthenticated", "Authentication required");
      }

      const userId = request.auth.uid;
      const { paymentIntentId } = request.data;

      if (!paymentIntentId) {
        throw new HttpsError("invalid-argument", "Payment intent ID required");
      }

      logger.info('Starting purchase confirmation', { userId, paymentIntentId });

      const stripe = getStripe();

      // Retrieve payment intent to verify status
      const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);

      if (paymentIntent.status !== "succeeded") {
        throw new HttpsError(
          "failed-precondition",
          `Payment not completed. Status: ${paymentIntent.status}`
        );
      }

      // Get pending payment record
      const pendingPaymentDoc = await db.collection("pendingPayments")
        .doc(paymentIntentId)
        .get();

      if (!pendingPaymentDoc.exists) {
        throw new HttpsError("not-found", "Payment record not found");
      }

      const pendingPayment = pendingPaymentDoc.data();
      const eventId = pendingPayment.eventId;

      // Process ticket creation in transaction
      return await db.runTransaction(async (transaction) => {
        const eventRef = db.collection("events").doc(eventId);
        const eventDoc = await transaction.get(eventRef);

        if (!eventDoc.exists) {
          throw new HttpsError("not-found", "Event not found");
        }

        const event = eventDoc.data();

        // Verify ticket availability
        if (event.maxTickets - event.ticketsSold < 1) {
          // Initiate refund if sold out
          await stripe.refunds.create({
            payment_intent: paymentIntentId,
            reason: 'requested_by_customer'
          });
          throw new HttpsError("failed-precondition", "Event sold out");
        }

        // Generate ticket data
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
          paymentIntentId,
          metadata: {
            paymentMethod: "apple_pay",
            customerEmail: request.auth.token.email,
            purchaseIp: request.rawRequest.ip
          }
        };

        // Update documents
        transaction.set(ticketRef, ticketData);
        transaction.update(eventRef, {
          ticketsSold: event.ticketsSold + 1,
          updatedAt: FieldValue.serverTimestamp()
        });
        transaction.update(pendingPaymentDoc.ref, {
          status: "completed",
          ticketId,
          completedAt: FieldValue.serverTimestamp()
        });

        logger.info('Purchase confirmed successfully', {
          ticketId,
          eventId,
          userId
        });

        return {
          success: true,
          ticketId,
          message: "Ticket purchased successfully!"
        };
      });

    } catch (error) {
      logger.error('Error confirming purchase', error);
      throw new HttpsError(
        error.code || "internal",
        error.message || "Error confirming purchase"
      );
    }
  }
);