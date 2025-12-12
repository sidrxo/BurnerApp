const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const { validateTicketAvailability, initiateRefund } = require("./paymentHelpers");
const { createTicketInTransaction } = require("../tickets/ticketHelpers");

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

exports.processApplePayPayment = onCall(
  { region: "europe-west2", secrets: [stripeSecretKey] },
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

      // Step 1: Create Stripe token and PaymentMethod in parallel
      logger.info('Creating Stripe token and payment method from Apple Pay');
      
      const token = await stripe.tokens.create({
        'card': {
          'token_data': paymentToken
        }
      });

      logger.info('Token created', { tokenId: token.id });

      const paymentMethod = await stripe.paymentMethods.create({
        type: 'card',
        card: {
          token: token.id
        }
      });

      logger.info('PaymentMethod created', { paymentMethodId: paymentMethod.id });

      // Step 2: Confirm the PaymentIntent
      logger.info('Confirming PaymentIntent');
      const paymentIntent = await stripe.paymentIntents.confirm(paymentIntentId, {
        payment_method: paymentMethod.id,
        return_url: 'https://burner.app/payment-complete'
      });

      logger.info('PaymentIntent confirmed', {
        status: paymentIntent.status,
        paymentIntentId: paymentIntent.id
      });

      // Step 3: Verify payment succeeded
      if (paymentIntent.status !== 'succeeded') {
        logger.error('Payment not succeeded', { status: paymentIntent.status });
        throw new HttpsError(
          "failed-precondition",
          `Payment not completed. Status: ${paymentIntent.status}`
        );
      }

      const eventId = pendingPayment.eventId;
      logger.info('Creating ticket for event', { eventId });

      // Step 4: Create ticket in transaction
      const result = await db.runTransaction(async (transaction) => {
        // Validate ticket availability within transaction
        let event, eventRef;
        try {
          const validation = await validateTicketAvailability(userId, eventId, transaction);
          event = validation.event;
          eventRef = validation.eventRef;
        } catch (validationError) {
          // Log failed purchase for manual reconciliation
          const failureReason = validationError.message;
          await db.collection("failedPurchases").add({
            userId,
            eventId,
            paymentIntentId,
            amount: paymentIntent.amount / 100,
            reason: failureReason,
            status: 'refund_initiated',
            paymentMethod: 'apple_pay',
            createdAt: FieldValue.serverTimestamp(),
            metadata: {
              eventName: pendingPayment.metadata?.eventName,
              customerEmail: request.auth.token.email
            }
          });

          // Initiate refund if validation fails
          logger.info('Validation failed, initiating refund', { error: failureReason });
          try {
            await initiateRefund(stripe, paymentIntentId,
              failureReason.includes('already have') ? 'duplicate' : 'requested_by_customer'
            );

            // Update failed purchase record with refund status
            await db.collection("failedPurchases")
              .where("paymentIntentId", "==", paymentIntentId)
              .limit(1)
              .get()
              .then(snapshot => {
                if (!snapshot.empty) {
                  snapshot.docs[0].ref.update({ status: 'refunded', refundedAt: FieldValue.serverTimestamp() });
                }
              });
          } catch (refundError) {
            logger.error('Refund failed', refundError);
            // Update failed purchase with refund failure
            await db.collection("failedPurchases")
              .where("paymentIntentId", "==", paymentIntentId)
              .limit(1)
              .get()
              .then(snapshot => {
                if (!snapshot.empty) {
                  snapshot.docs[0].ref.update({
                    status: 'refund_failed',
                    refundError: refundError.message,
                    updatedAt: FieldValue.serverTimestamp()
                  });
                }
              });
          }
          throw validationError;
        }

        // Simplified payment method details
        const paymentMethodDetails = {
          id: paymentMethod.id,
          wallet: "apple_pay",
          type: "apple_pay"
        };

        // Create ticket using consolidated helper
        const ticketRef = db.collection("tickets").doc();
        const { ticketId } = createTicketInTransaction(transaction, {
          ticketRef,
          eventRef,
          event: { ...event, id: eventId },
          userId,
          paymentIntentId,
          paymentMethodDetails,
          customerEmail: request.auth.token.email || null
        });

        // Delete pending payment instead of updating
        transaction.delete(pendingPaymentDoc.ref);

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
  { 
    region: "europe-west2", 
    secrets: [stripeSecretKey],
  },
  async (request) => {
    const startTime = Date.now();
    
    try {
      logger.info('createPaymentIntent called', { 
        hasAuth: !!request.auth,
        eventId: request.data?.eventId 
      });

      if (!request.auth) {
        throw new HttpsError("unauthenticated", "Authentication required");
      }

      const userId = request.auth.uid;
      const { eventId } = request.data;

      if (!eventId) {
        throw new HttpsError("invalid-argument", "Event ID required");
      }

      // ✅ OPTIMIZATION: Fetch event and user data in PARALLEL
      const [eventDoc, userDoc] = await Promise.all([
        db.collection("events").doc(eventId).get(),
        db.collection("users").doc(userId).get()
      ]);

      if (!eventDoc.exists) {
        throw new HttpsError("not-found", "Event not found");
      }

      const event = eventDoc.data();
      logger.info('Event found', { 
        eventName: event.name, 
        price: event.price,
        fetchTime: Date.now() - startTime 
      });

      const stripe = getStripe();
      let customerId = userDoc.data()?.stripeCustomerId;
      const userEmail = userDoc.data()?.email || request.auth.token.email || null;

      // ✅ OPTIMIZATION: Create customer if needed (unavoidable for first-time users)
      if (!customerId) {
        logger.info('Creating new Stripe customer', { userId, email: userEmail });
        const customerData = {
          metadata: {
            firebaseUID: userId,
            createdAt: new Date().toISOString()
          }
        };
        
        if (userEmail) {
          customerData.email = userEmail;
        }
        
        const customer = await stripe.customers.create(customerData);
        customerId = customer.id;
        
        // ✅ OPTIMIZATION: Don't await this - write asynchronously
        db.collection("users").doc(userId).update({
          stripeCustomerId: customerId,
          updatedAt: FieldValue.serverTimestamp()
        }).catch(err => {
          logger.error("Failed to save customerId", err, { userId, customerId });
        });
      }

      // Create payment intent
      logger.info('Creating Stripe payment intent', { 
        amount: event.price * 100,
        customerTime: Date.now() - startTime 
      });
      
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
        payment_method_types: ['card'],
        capture_method: "automatic",
        statement_descriptor: "BURNER TICKET",
        statement_descriptor_suffix: event.name.substring(0, 15)
      });

      logger.info('Payment intent created successfully', { 
        paymentIntentId: paymentIntent.id,
        intentTime: Date.now() - startTime
      });

      // ✅ OPTIMIZATION: Don't await this - write asynchronously
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
      
      if (userEmail) {
        pendingPaymentData.metadata.customerEmail = userEmail;
      }
      
      db.collection("pendingPayments").doc(paymentIntent.id).set(pendingPaymentData)
        .catch(err => {
          logger.error("Failed to save pending payment", err, { paymentIntentId: paymentIntent.id });
        });

      logger.info('Payment intent process completed', {
        paymentIntentId: paymentIntent.id,
        totalTime: Date.now() - startTime
      });

      return {
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
        amount: event.price
      };

    } catch (error) {
      logger.error('Error creating payment intent', error, {
        userId: request.auth?.uid,
        eventId: request.data?.eventId,
        totalTime: Date.now() - startTime
      });

      if (error.code && error.code.includes('/')) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        error.message || "Error creating payment intent"
      );
    }
  }
);

// -------------------------
exports.confirmPurchase = onCall(
  { 
    region: "europe-west2", 
    secrets: [stripeSecretKey],
  },
  async (request) => {
    const startTime = Date.now();
    
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

      const stripe = getStripe();

      // ✅ OPTIMIZATION: Fetch pending payment and verify payment in PARALLEL
      const [pendingPaymentDoc, paymentIntent] = await Promise.all([
        db.collection("pendingPayments").doc(paymentIntentId).get(),
        stripe.paymentIntents.retrieve(paymentIntentId)
      ]);

      logger.info('Data fetched in parallel', { 
        fetchTime: Date.now() - startTime 
      });

      if (!pendingPaymentDoc.exists) {
        throw new HttpsError("not-found", "Payment record not found");
      }

      const pendingPayment = pendingPaymentDoc.data();
      
      // Check if already processed
      if (pendingPayment.status === "completed") {
        throw new HttpsError("already-exists", "Ticket already created for this payment");
      }

      // Verify payment status
      if (paymentIntent.status !== "succeeded") {
        throw new HttpsError(
          "failed-precondition",
          `Payment not completed. Status: ${paymentIntent.status}`
        );
      }

      // Verify ownership
      if (paymentIntent.metadata.userId !== userId) {
        throw new HttpsError("permission-denied", "Unauthorized");
      }

      logger.info('Payment verified', { verifyTime: Date.now() - startTime });

      const eventId = pendingPayment.eventId;

      // ✅ OPTIMIZATION: Use batch writes instead of transaction for better performance
      // Only use transaction for the critical validation step
      const result = await db.runTransaction(async (transaction) => {
        // Validate ticket availability
        let event, eventRef;
        try {
          const validation = await validateTicketAvailability(userId, eventId, transaction);
          event = validation.event;
          eventRef = validation.eventRef;
        } catch (validationError) {
          // Handle validation failure (existing refund logic)
          const failureReason = validationError.message;
          
          // ✅ Don't await - log asynchronously
          db.collection("failedPurchases").add({
            userId,
            eventId,
            paymentIntentId,
            amount: paymentIntent.amount / 100,
            reason: failureReason,
            status: 'refund_initiated',
            createdAt: FieldValue.serverTimestamp(),
            metadata: {
              eventName: pendingPayment.metadata?.eventName,
              customerEmail: request.auth.token.email
            }
          }).catch(err => logger.error("Failed to log failed purchase", err));

          // Initiate refund
          try {
            await initiateRefund(stripe, paymentIntentId,
              failureReason.includes('already have') ? 'duplicate' : 'requested_by_customer'
            );
          } catch (refundError) {
            logger.error('Refund failed', refundError);
          }
          
          throw validationError;
        }

        // Simplified payment method details
        const paymentMethodId = paymentIntent.payment_method;
        const paymentMethodDetails = paymentMethodId ? {
          id: paymentMethodId,
          type: "card"
        } : null;

        // Create ticket
        const ticketRef = db.collection("tickets").doc();
        const { ticketId } = createTicketInTransaction(transaction, {
          ticketRef,
          eventRef,
          event: { ...event, id: eventId },
          userId,
          paymentIntentId,
          paymentMethodDetails,
          customerEmail: request.auth.token.email || null
        });

        // Delete pending payment
        transaction.delete(pendingPaymentDoc.ref);

        logger.info('Purchase confirmed successfully', {
          ticketId,
          eventId,
          userId,
          totalTime: Date.now() - startTime
        });

        return {
          success: true,
          ticketId,
          message: "Ticket purchased successfully!"
        };
      });

      return result;

    } catch (error) {
      logger.error('Error confirming purchase', error, {
        userId: request.auth?.uid,
        paymentIntentId: request.data?.paymentIntentId,
        totalTime: Date.now() - startTime
      });

      // Log failed purchase (existing logic)
      if (request.data?.paymentIntentId) {
        db.collection("failedPurchases")
          .where("paymentIntentId", "==", request.data.paymentIntentId)
          .limit(1)
          .get()
          .then(existingFailure => {
            if (existingFailure.empty) {
              return db.collection("failedPurchases").add({
                userId: request.auth?.uid,
                paymentIntentId: request.data.paymentIntentId,
                reason: error.message || "Unknown error during confirmation",
                status: 'error',
                createdAt: FieldValue.serverTimestamp(),
                errorDetails: {
                  code: error.code,
                  message: error.message
                }
              });
            }
          })
          .catch(logError => logger.error('Failed to log failed purchase', logError));
      }

      if (error.code && error.code.includes('/')) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        error.message || "Error confirming purchase"
      );
    }
  }
);

// -------------------------
// Get Payment Methods
// -------------------------
exports.getPaymentMethods = onCall(
  { region: "europe-west2", secrets: [stripeSecretKey] },
  async (request) => {
    try {
      logger.info('getPaymentMethods called', {
        hasAuth: !!request.auth
      });

      if (!request.auth) {
        throw new HttpsError("unauthenticated", "Authentication required");
      }

      const userId = request.auth.uid;

      // Get user's Stripe customer ID
      const userDoc = await db.collection("users").doc(userId).get();
      const customerId = userDoc.data()?.stripeCustomerId;

      if (!customerId) {
        logger.info('No customer ID found for user', { userId });
        return {
          paymentMethods: []
        };
      }

      const stripe = getStripe();

      // Retrieve all payment methods for this customer
      const paymentMethods = await stripe.paymentMethods.list({
        customer: customerId,
        type: 'card'
      });

      // Get customer to check default payment method
      const customer = await stripe.customers.retrieve(customerId);

      logger.info('Payment methods retrieved', {
        userId,
        count: paymentMethods.data.length
      });

      // Format payment methods for client
      const formattedMethods = paymentMethods.data.map(pm => ({
        id: pm.id,
        brand: pm.card.brand,
        last4: pm.card.last4,
        expMonth: pm.card.exp_month,
        expYear: pm.card.exp_year,
        isDefault: customer.invoice_settings.default_payment_method === pm.id
      }));

      return {
        paymentMethods: formattedMethods
      };

    } catch (error) {
      logger.error('Error getting payment methods', error, {
        userId: request.auth?.uid
      });

      if (error.code && error.code.includes('/')) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        error.message || "Error retrieving payment methods"
      );
    }
  }
);

// -------------------------
// Save Payment Method
// -------------------------
exports.savePaymentMethod = onCall(
  { region: "europe-west2", secrets: [stripeSecretKey] },
  async (request) => {
    try {
      logger.info('savePaymentMethod called', {
        hasAuth: !!request.auth
      });

      if (!request.auth) {
        throw new HttpsError("unauthenticated", "Authentication required");
      }

      const userId = request.auth.uid;
      const { paymentMethodId, setAsDefault } = request.data;

      if (!paymentMethodId) {
        throw new HttpsError("invalid-argument", "Payment method ID required");
      }

      const stripe = getStripe();

      // Get or create customer
      const userDoc = await db.collection("users").doc(userId).get();
      let customerId = userDoc.data()?.stripeCustomerId;
      const userEmail = userDoc.data()?.email || request.auth.token.email || null;

      if (!customerId) {
        logger.info('Creating new Stripe customer', { userId, email: userEmail });
        const customerData = {
          metadata: {
            firebaseUID: userId,
            createdAt: new Date().toISOString()
          }
        };

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
      }

      // Attach payment method to customer
      await stripe.paymentMethods.attach(paymentMethodId, {
        customer: customerId
      });

      logger.info('Payment method attached', { paymentMethodId, customerId });

      // Set as default if requested
      if (setAsDefault) {
        await stripe.customers.update(customerId, {
          invoice_settings: {
            default_payment_method: paymentMethodId
          }
        });
        logger.info('Payment method set as default', { paymentMethodId });
      }

      return {
        success: true,
        message: "Payment method saved successfully"
      };

    } catch (error) {
      logger.error('Error saving payment method', error, {
        userId: request.auth?.uid
      });

      if (error.code && error.code.includes('/')) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        error.message || "Error saving payment method"
      );
    }
  }
);

// -------------------------
// Delete Payment Method
// -------------------------
exports.deletePaymentMethod = onCall(
  { region: "europe-west2", secrets: [stripeSecretKey] },
  async (request) => {
    try {
      logger.info('deletePaymentMethod called', {
        hasAuth: !!request.auth,
        paymentMethodId: request.data?.paymentMethodId
      });

      if (!request.auth) {
        throw new HttpsError("unauthenticated", "Authentication required");
      }

      const userId = request.auth.uid;
      const { paymentMethodId } = request.data;

      if (!paymentMethodId) {
        throw new HttpsError("invalid-argument", "Payment method ID required");
      }

      const stripe = getStripe();

      // Verify the payment method belongs to this user's customer
      const userDoc = await db.collection("users").doc(userId).get();
      const customerId = userDoc.data()?.stripeCustomerId;

      if (!customerId) {
        logger.error('Customer ID not found', { userId });
        throw new HttpsError("not-found", "Customer not found");
      }

      logger.info('Retrieved customer', { customerId, userId });

      // Retrieve payment method to verify it belongs to this customer
      let paymentMethod;
      try {
        paymentMethod = await stripe.paymentMethods.retrieve(paymentMethodId);
        logger.info('Payment method retrieved', {
          paymentMethodId,
          customer: paymentMethod.customer,
          expectedCustomer: customerId
        });
      } catch (retrieveError) {
        logger.error('Failed to retrieve payment method', retrieveError, {
          paymentMethodId,
          userId
        });
        throw new HttpsError("not-found", "Payment method not found");
      }

      if (paymentMethod.customer !== customerId) {
        logger.error('Payment method does not belong to customer', {
          paymentMethodCustomer: paymentMethod.customer,
          userCustomer: customerId,
          userId
        });
        throw new HttpsError("permission-denied", "Unauthorized");
      }

      // Detach payment method from customer
      logger.info('Attempting to detach payment method', { paymentMethodId });
      const detached = await stripe.paymentMethods.detach(paymentMethodId);
      logger.info('Payment method detached successfully', {
        paymentMethodId,
        detachedCustomer: detached.customer,
        userId
      });

      return {
        success: true,
        message: "Payment method deleted successfully"
      };

    } catch (error) {
      logger.error('Error deleting payment method', error, {
        userId: request.auth?.uid,
        paymentMethodId: request.data?.paymentMethodId,
        errorCode: error.code,
        errorType: error.type
      });

      if (error.code && error.code.includes('/')) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        error.message || "Error deleting payment method"
      );
    }
  }
);

// -------------------------
// Set Default Payment Method
// -------------------------
exports.setDefaultPaymentMethod = onCall(
  { region: "europe-west2", secrets: [stripeSecretKey] },
  async (request) => {
    try {
      logger.info('setDefaultPaymentMethod called', {
        hasAuth: !!request.auth
      });

      if (!request.auth) {
        throw new HttpsError("unauthenticated", "Authentication required");
      }

      const userId = request.auth.uid;
      const { paymentMethodId } = request.data;

      if (!paymentMethodId) {
        throw new HttpsError("invalid-argument", "Payment method ID required");
      }

      const stripe = getStripe();

      // Get customer
      const userDoc = await db.collection("users").doc(userId).get();
      const customerId = userDoc.data()?.stripeCustomerId;

      if (!customerId) {
        throw new HttpsError("not-found", "Customer not found");
      }

      // Verify the payment method belongs to this customer
      const paymentMethod = await stripe.paymentMethods.retrieve(paymentMethodId);

      if (paymentMethod.customer !== customerId) {
        throw new HttpsError("permission-denied", "Unauthorized");
      }

      // Update customer's default payment method
      await stripe.customers.update(customerId, {
        invoice_settings: {
          default_payment_method: paymentMethodId
        }
      });

      logger.info('Default payment method set', { paymentMethodId, userId });

      return {
        success: true,
        message: "Default payment method updated successfully"
      };

    } catch (error) {
      logger.error('Error setting default payment method', error, {
        userId: request.auth?.uid
      });

      if (error.code && error.code.includes('/')) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        error.message || "Error setting default payment method"
      );
    }
  }
);