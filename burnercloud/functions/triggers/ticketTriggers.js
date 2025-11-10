const { onDocumentCreated, onDocumentDeleted, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

const db = getFirestore();

/**
 * Update eventStats when a ticket is created
 */
exports.onTicketCreated = onDocumentCreated({
  document: "tickets/{ticketId}",
  region: "europe-west2"
}, async (event) => {
  try {
    const ticket = event.data.data();
    const eventId = ticket.eventId;

    if (!eventId) {
      console.warn("Ticket created without eventId:", event.params.ticketId);
      return;
    }

    const eventStatsRef = db.collection("eventStats").doc(eventId);
    const eventRef = db.collection("events").doc(eventId);

    await db.runTransaction(async (transaction) => {
      const eventStatsDoc = await transaction.get(eventStatsRef);
      const eventDoc = await transaction.get(eventRef);

      if (!eventDoc.exists) {
        console.warn("Event not found for ticket:", eventId);
        return;
      }

      const ticketPrice = ticket.totalPrice || 0;

      if (eventStatsDoc.exists) {
        // Update existing stats
        transaction.update(eventStatsRef, {
          ticketsSold: FieldValue.increment(1),
          totalRevenue: FieldValue.increment(ticketPrice),
          updatedAt: FieldValue.serverTimestamp()
        });
      } else {
        // Create new stats document
        const eventData = eventDoc.data();
        transaction.set(eventStatsRef, {
          eventId: eventId,
          eventName: eventData.name,
          venueId: eventData.venueId || null,
          ticketsSold: 1,
          ticketsUsed: 0,
          totalRevenue: ticketPrice,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp()
        });
      }
    });

    console.log(`EventStats updated for ticket creation: ${event.params.ticketId}`);
  } catch (error) {
    console.error("Error updating eventStats on ticket creation:", error);
  }
});

/**
 * Update eventStats when a ticket is updated (e.g., marked as used)
 */
exports.onTicketUpdated = onDocumentUpdated({
  document: "tickets/{ticketId}",
  region: "europe-west2"
}, async (event) => {
  try {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const eventId = after.eventId;

    if (!eventId) {
      console.warn("Ticket updated without eventId:", event.params.ticketId);
      return;
    }

    // Check if ticket status changed to 'used'
    const wasUsed = before.status === 'used' || before.isUsed === true;
    const isUsed = after.status === 'used' || after.isUsed === true;

    if (!wasUsed && isUsed) {
      // Ticket was just marked as used
      const eventStatsRef = db.collection("eventStats").doc(eventId);
      await eventStatsRef.update({
        ticketsUsed: FieldValue.increment(1),
        updatedAt: FieldValue.serverTimestamp()
      });

      console.log(`EventStats updated for ticket usage: ${event.params.ticketId}`);
    }

    // Check if ticket status changed to 'refunded'
    const wasRefunded = before.status === 'refunded';
    const isRefunded = after.status === 'refunded';

    if (!wasRefunded && isRefunded) {
      // Ticket was refunded, decrement stats
      const eventStatsRef = db.collection("eventStats").doc(eventId);
      const ticketPrice = after.totalPrice || 0;

      await db.runTransaction(async (transaction) => {
        const eventStatsDoc = await transaction.get(eventStatsRef);

        if (eventStatsDoc.exists) {
          transaction.update(eventStatsRef, {
            ticketsSold: FieldValue.increment(-1),
            totalRevenue: FieldValue.increment(-ticketPrice),
            updatedAt: FieldValue.serverTimestamp()
          });

          // Also decrement ticketsUsed if the ticket was used
          if (wasUsed) {
            transaction.update(eventStatsRef, {
              ticketsUsed: FieldValue.increment(-1)
            });
          }
        }
      });

      console.log(`EventStats updated for ticket refund: ${event.params.ticketId}`);
    }
  } catch (error) {
    console.error("Error updating eventStats on ticket update:", error);
  }
});

/**
 * Update eventStats when a ticket is deleted
 */
exports.onTicketDeleted = onDocumentDeleted({
  document: "tickets/{ticketId}",
  region: "europe-west2"
}, async (event) => {
  try {
    const ticket = event.data.data();
    const eventId = ticket.eventId;

    if (!eventId) {
      console.warn("Ticket deleted without eventId:", event.params.ticketId);
      return;
    }

    const eventStatsRef = db.collection("eventStats").doc(eventId);
    const ticketPrice = ticket.totalPrice || 0;
    const wasUsed = ticket.status === 'used' || ticket.isUsed === true;

    await db.runTransaction(async (transaction) => {
      const eventStatsDoc = await transaction.get(eventStatsRef);

      if (eventStatsDoc.exists) {
        const updates = {
          ticketsSold: FieldValue.increment(-1),
          totalRevenue: FieldValue.increment(-ticketPrice),
          updatedAt: FieldValue.serverTimestamp()
        };

        if (wasUsed) {
          updates.ticketsUsed = FieldValue.increment(-1);
        }

        transaction.update(eventStatsRef, updates);
      }
    });

    console.log(`EventStats updated for ticket deletion: ${event.params.ticketId}`);
  } catch (error) {
    console.error("Error updating eventStats on ticket deletion:", error);
  }
});
