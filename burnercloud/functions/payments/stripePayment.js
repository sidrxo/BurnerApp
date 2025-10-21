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
// Process Apple Pay Payment (All-in-one function)
// -------------------------
exports.processApplePayPayment = onCall(
  { secrets: [stripeSecretKey] },
  async (request) => {
    try {
      logger.info('processApplePayPayment called', {
        hasAuth: !!request.auth,
        paymentIntentId: request.data?.paymentIntentId
      });

      if (!request.auth) {
        throw new HttpsError("unauthenticated", "Authentication required");
      }

      const userId = request.auth.uid;
      const { paymentIntentId, paymentToken } = request.data;

      if (!paymentIntentId || !paymentToken) {
        throw new HttpsError("invalid-argument", "Missing required parameters");
      }

      logger.info('Processing Apple Pay payment', { userId, paymentIntentId });

      const stripe = getStripe();

      // Step 1: Create a Stripe token from the Apple Pay token
      logger.info('Creating Stripe token from Apple Pay');
      const token = await stripe.tokens.create({
        'card': {
          'token_data': paymentToken
        }
      });

      logger.info('Token created', { tokenId: token.id });

      // Step 2: Create PaymentMethod from token
      logger.info('Creating PaymentMethod');
      const paymentMethod = await stripe.paymentMethods.create({
        type: 'card',
        card: {
          token: token.id
        }
      });

      logger.info('PaymentMethod created', { paymentMethodId: paymentMethod.id });

      // Step 3: Confirm the PaymentIntent
      logger.info('Confirming PaymentIntent');
      const paymentIntent = await stripe.paymentIntents.confirm(paymentIntentId, {
        payment_method: paymentMethod.id,
        return_url: 'https://burner.app/payment-complete'
      });

      logger.info('PaymentIntent confirmed', {
        status: paymentIntent.status,
        paymentIntentId: paymentIntent.id
      });

      // Step 4: Verify payment succeeded
      if (paymentIntent.status !== 'succeeded') {
        logger.error('Payment not succeeded', { status: paymentIntent.status });
        throw new HttpsError(
          "failed-precondition",
          `Payment not completed. Status: ${paymentIntent.status}`
        );
      }

      // Step 5: Get pending payment record
      const pendingPaymentDoc = await db.collection("pendingPayments")
        .doc(paymentIntentId)
        .get();

      if (!pendingPaymentDoc.exists) {
        logger.error('Payment record not found', { paymentIntentId });
        throw new HttpsError("not-found", "Payment record not found");
      }

      const pendingPayment = pendingPaymentDoc.data();
      const eventId = pendingPayment.eventId;

      logger.info('Creating ticket for event', { eventId });

      // Step 6: Create ticket in transaction
      const result = await db.runTransaction(async (transaction) => {
        const eventRef = db.collection("events").doc(eventId);
        const eventDoc = await transaction.get(eventRef);

        if (!eventDoc.exists) {
          throw new HttpsError("not-found", "Event not found");
        }

        const event = eventDoc.data();

        // Verify ticket availability
        if (event.maxTickets - event.ticketsSold < 1) {
          logger.info('Event sold out, initiating refund');
          await stripe.refunds.create({
            payment_intent: paymentIntentId,
            reason: 'requested_by_customer'
          });
          throw new HttpsError("failed-precondition", "Event sold out - refund initiated");
        }

        // Check for duplicate ticket
        const existingTickets = await db.collection("tickets")
          .where("userId", "==", userId)
          .where("eventId", "==", eventId)
          .where("status", "==", "confirmed")
          .limit(1)
          .get();

        if (!existingTickets.empty) {
          logger.info('Duplicate ticket detected, initiating refund');
          await stripe.refunds.create({
            payment_intent: paymentIntentId,
            reason: 'duplicate'
          });
          throw new HttpsError("failed-precondition", "You already have a ticket - refund initiated");
        }

        // Generate ticket data
        const ticketRef = db.collection("tickets").doc();
        const ticketId = ticketRef.id;
        let ticketNumber, qrCodeData;
        
        try {
          const { generateQRCodeData, generateTicketNumber } = require("../tickets/ticketHelpers");
          ticketNumber = generateTicketNumber();
          qrCodeData = generateQRCodeData(ticketId, eventId, userId, ticketNumber);
          logger.info('Ticket data generated', { ticketId, ticketNumber });
        } catch (helperError) {
          logger.error('Error with ticketHelpers, using fallback', helperError);
          ticketNumber = Math.floor(100000 + Math.random() * 900000).toString();
          qrCodeData = JSON.stringify({
            ticketId,
            eventId,
            userId,
            ticketNumber,
            timestamp: new Date().toISOString()
          });
        }

        // Build ticket metadata
        const ticketMetadata = {
          paymentMethod: "apple_pay",
          last4: paymentMethod.card?.last4 || null,
          brand: paymentMethod.card?.brand || null
        };
        
        if (request.auth.token.email) {
          ticketMetadata.customerEmail = request.auth.token.email;
        }

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
          paymentMethodId: paymentMethod.id,
          metadata: ticketMetadata
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
          paymentMethodId: paymentMethod.id,
          completedAt: FieldValue.serverTimestamp()
        });

        logger.info('Ticket created successfully', {
          ticketId,
          eventId,
          userId,
          paymentIntentId
        });

        return {
          success: true,
          ticketId,
          message: "Ticket purchased successfully!"
        };
      });

      return result;

    } catch (error) {
      logger.error('Error processing Apple Pay payment', error, {
        userId: request.auth?.uid,
        paymentIntentId: request.data?.paymentIntentId
      });
      
      // Re-throw HttpsErrors as-is
      if (error.code && error.code.includes('/')) {
        throw error;
      }
      
      throw new HttpsError(
        "internal",
        error.message || "Error processing payment"
      );
    }
  }
);

// -------------------------
// Create Payment Intent
// -------------------------
exports.createPaymentIntent = onCall(
  { secrets: [stripeSecretKey] },
  async (request) => {
    try {
      logger.info('createPaymentIntent called', { 
        hasAuth: !!request.auth,
        eventId: request.data?.eventId 
      });

      if (!request.auth) {
        logger.error('Authentication required', {});
        throw new HttpsError("unauthenticated", "Authentication required");
      }

      const userId = request.auth.uid;
      const { eventId } = request.data;

      if (!eventId) {
        logger.error('Missing eventId', { userId });
        throw new HttpsError("invalid-argument", "Event ID required");
      }

      logger.info('Creating payment intent', { userId, eventId });

      // Get event details
      const eventDoc = await db.collection("events").doc(eventId).get();
      if (!eventDoc.exists) {
        logger.error('Event not found', { userId, eventId });
        throw new HttpsError("not-found", "Event not found");
      }

      const event = eventDoc.data();
      logger.info('Event found', { eventName: event.name, price: event.price });

      // Check ticket availability
      if (event.maxTickets - event.ticketsSold < 1) {
        logger.error('No tickets available', { userId, eventId });
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
        logger.error('User already has ticket', { userId, eventId });
        throw new HttpsError("failed-precondition", "You already have a ticket for this event");
      }

      const stripe = getStripe();
      logger.info('Stripe initialized');

      // Get or create customer
      const userDoc = await db.collection("users").doc(userId).get();
      let customerId = userDoc.data()?.stripeCustomerId;
      
      // Get email from user document or auth token, with fallback
      const userEmail = userDoc.data()?.email || request.auth.token.email || null;

      if (!customerId) {
        logger.info('Creating new Stripe customer', { userId, email: userEmail });
        const customerData = {
          metadata: {
            firebaseUID: userId,
            createdAt: new Date().toISOString()
          }
        };
        
        // Only add email if it exists
        if (userEmail) {
          customerData.email = userEmail;
        }
        
        const customer = await stripe.customers.create(customerData);
        customerId = customer.id;
        await db.collection("users").doc(userId).update({
          stripeCustomerId: customerId,
          updatedAt: FieldValue.serverTimestamp()
        });
        logger.info('Stripe customer created', { customerId });
      } else {
        logger.info('Using existing Stripe customer', { customerId });
      }

      // Create payment intent - simplified for mobile
      logger.info('Creating Stripe payment intent', { amount: event.price * 100 });
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
        // Use manual payment method types instead of automatic
        payment_method_types: ['card'],
        capture_method: "automatic",
        statement_descriptor: "BURNER TICKET",
        statement_descriptor_suffix: event.name.substring(0, 15)
      });

      logger.info('Payment intent created successfully', { paymentIntentId: paymentIntent.id });

      // Record pending payment (handle undefined email)
      const pendingPaymentData = {
        userId,
        eventId,
        amount: event.price,
        status: "pending",
        createdAt: FieldValue.serverTimestamp(),
        metadata: {
          eventName: event.name,
          customerId: customerId
        }
      };
      
      // Only add customerEmail if it exists
      if (userEmail) {
        pendingPaymentData.metadata.customerEmail = userEmail;
      }
      
      await db.collection("pendingPayments").doc(paymentIntent.id).set(pendingPaymentData);

      logger.info('Payment intent created', {
        paymentIntentId: paymentIntent.id,
        userId,
        eventId
      });

      return {
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
        amount: event.price,
        publishableKey: "pk_test_YOUR_KEY_HERE" // Optional: return your publishable key
      };

    } catch (error) {
      logger.error('Error creating payment intent', error, {
        userId: request.auth?.uid,
        eventId: request.data?.eventId
      });
      
      // Re-throw HttpsErrors as-is
      if (error.code && error.code.includes('/')) {
        throw error;
      }
      
      // Wrap other errors
      throw new HttpsError(
        "internal",
        error.message || "Error creating payment intent"
      );
    }
  }
);

// -------------------------
// Confirm Purchase (create ticket after payment succeeds)
// -------------------------
exports.confirmPurchase = onCall(
  { secrets: [stripeSecretKey] },
  async (request) => {
    try {
      logger.info('confirmPurchase called', {
        hasAuth: !!request.auth,
        paymentIntentId: request.data?.paymentIntentId
      });

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
      logger.info('Retrieving payment intent from Stripe');
      const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);

      if (paymentIntent.status !== "succeeded") {
        logger.error('Payment not completed', { status: paymentIntent.status });
        throw new HttpsError(
          "failed-precondition",
          `Payment not completed. Status: ${paymentIntent.status}`
        );
      }

      logger.info('Payment verified as succeeded');

      // Verify this payment belongs to this user
      if (paymentIntent.metadata.userId !== userId) {
        logger.error('Payment does not belong to user', {
          paymentUserId: paymentIntent.metadata.userId,
          requestUserId: userId
        });
        throw new HttpsError("permission-denied", "Unauthorized");
      }

      // Get pending payment record
      const pendingPaymentDoc = await db.collection("pendingPayments")
        .doc(paymentIntentId)
        .get();

      if (!pendingPaymentDoc.exists) {
        logger.error('Payment record not found', { paymentIntentId });
        throw new HttpsError("not-found", "Payment record not found");
      }

      const pendingPayment = pendingPaymentDoc.data();
      
      // Check if already processed
      if (pendingPayment.status === "completed") {
        logger.info('Payment already processed', { paymentIntentId });
        throw new HttpsError("already-exists", "Ticket already created for this payment");
      }

      const eventId = pendingPayment.eventId;
      logger.info('Processing ticket for event', { eventId });

      // Process ticket creation in transaction
      return await db.runTransaction(async (transaction) => {
        const eventRef = db.collection("events").doc(eventId);
        const eventDoc = await transaction.get(eventRef);

        if (!eventDoc.exists) {
          logger.error('Event not found', { eventId });
          throw new HttpsError("not-found", "Event not found");
        }

        const event = eventDoc.data();

        // Verify ticket availability
        if (event.maxTickets - event.ticketsSold < 1) {
          // Initiate refund if sold out
          logger.info('Event sold out, initiating refund');
          await stripe.refunds.create({
            payment_intent: paymentIntentId,
            reason: 'requested_by_customer'
          });
          throw new HttpsError("failed-precondition", "Event sold out - refund initiated");
        }

        // Check for duplicate ticket
        const existingTickets = await db.collection("tickets")
          .where("userId", "==", userId)
          .where("eventId", "==", eventId)
          .where("status", "==", "confirmed")
          .limit(1)
          .get();

        if (!existingTickets.empty) {
          logger.info('Duplicate ticket detected, initiating refund');
          await stripe.refunds.create({
            payment_intent: paymentIntentId,
            reason: 'duplicate'
          });
          throw new HttpsError("failed-precondition", "You already have a ticket - refund initiated");
        }

        // Generate ticket data using ticketHelpers
        const ticketRef = db.collection("tickets").doc();
        const ticketId = ticketRef.id;
        let ticketNumber, qrCodeData;
        
        try {
          const { generateQRCodeData, generateTicketNumber } = require("./ticketHelpers");
          ticketNumber = generateTicketNumber();
          qrCodeData = generateQRCodeData(ticketId, eventId, userId, ticketNumber);
          logger.info('Ticket data generated with helpers', { ticketId, ticketNumber });
        } catch (helperError) {
          logger.error('Error loading ticketHelpers, using fallback', helperError);
          // Fallback if ticketHelpers not available
          ticketNumber = Math.floor(100000 + Math.random() * 900000).toString();
          qrCodeData = JSON.stringify({
            ticketId,
            eventId,
            userId,
            ticketNumber,
            timestamp: new Date().toISOString()
          });
        }

        // Get payment method details
        const paymentMethodId = paymentIntent.payment_method;
        let paymentMethodDetails = {};
        
        if (paymentMethodId) {
          try {
            const paymentMethod = await stripe.paymentMethods.retrieve(paymentMethodId);
            paymentMethodDetails = {
              last4: paymentMethod.card?.last4 || null,
              brand: paymentMethod.card?.brand || null,
              wallet: paymentMethod.card?.wallet?.type || null
            };
          } catch (pmError) {
            logger.error('Error retrieving payment method', pmError);
            // Continue without payment method details
          }
        }

        // Build ticket metadata (handle undefined email)
        const ticketMetadata = {
          paymentMethod: paymentMethodDetails.wallet || "card",
          ...paymentMethodDetails
        };
        
        // Only add customerEmail if it exists
        if (request.auth.token.email) {
          ticketMetadata.customerEmail = request.auth.token.email;
        }

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
          metadata: ticketMetadata
        };

        // Update documents in transaction
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
          userId,
          paymentMethod: paymentMethodDetails.wallet || "card"
        });

        return {
          success: true,
          ticketId,
          message: "Ticket purchased successfully!"
        };
      });

    } catch (error) {
      logger.error('Error confirming purchase', error, {
        userId: request.auth?.uid,
        paymentIntentId: request.data?.paymentIntentId
      });
      
      // Re-throw HttpsErrors as-is
      if (error.code && error.code.includes('/')) {
        throw error;
      }
      
      // Wrap other errors
      throw new HttpsError(
        "internal",
        error.message || "Error confirming purchase"
      );
    }
  }
);