const { onDocumentCreated, onDocumentDeleted, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

const db = getFirestore();

/**
 * Helper function to create an audit log entry
 */
async function createAuditLog(action, resource, resourceId, userId, details = {}) {
  try {
    await db.collection("auditLogs").add({
      action,
      resource,
      resourceId,
      userId,
      timestamp: FieldValue.serverTimestamp(),
      details
    });
  } catch (error) {
    console.error("Error creating audit log:", error);
  }
}

/**
 * Log admin creation
 */
exports.onAdminCreated = onDocumentCreated("admins/{adminId}", async (event) => {
  const admin = event.data.data();
  const adminId = event.params.adminId;

  await createAuditLog(
    "admin_created",
    "admin",
    adminId,
    admin.createdBy || "system",
    {
      email: admin.email,
      name: admin.name,
      role: admin.role,
      venueId: admin.venueId || null
    }
  );

  console.log(`Audit log created for admin creation: ${adminId}`);
});

/**
 * Log admin updates
 */
exports.onAdminUpdated = onDocumentUpdated("admins/{adminId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  const adminId = event.params.adminId;

  // Determine what changed
  const changes = {};
  if (before.role !== after.role) changes.role = { from: before.role, to: after.role };
  if (before.active !== after.active) changes.active = { from: before.active, to: after.active };
  if (before.venueId !== after.venueId) changes.venueId = { from: before.venueId, to: after.venueId };

  await createAuditLog(
    "admin_updated",
    "admin",
    adminId,
    after.updatedBy || "system",
    {
      email: after.email,
      changes
    }
  );

  console.log(`Audit log created for admin update: ${adminId}`);
});

/**
 * Log admin deletion
 */
exports.onAdminDeleted = onDocumentDeleted("admins/{adminId}", async (event) => {
  const admin = event.data.data();
  const adminId = event.params.adminId;

  await createAuditLog(
    "admin_deleted",
    "admin",
    adminId,
    "system", // We can't know who deleted it from the trigger alone
    {
      email: admin.email,
      name: admin.name,
      role: admin.role
    }
  );

  console.log(`Audit log created for admin deletion: ${adminId}`);
});

/**
 * Log scanner creation
 */
exports.onScannerCreated = onDocumentCreated("scanners/{scannerId}", async (event) => {
  const scanner = event.data.data();
  const scannerId = event.params.scannerId;

  await createAuditLog(
    "scanner_created",
    "scanner",
    scannerId,
    scanner.createdBy || "system",
    {
      email: scanner.email,
      name: scanner.name,
      venueId: scanner.venueId || null
    }
  );

  console.log(`Audit log created for scanner creation: ${scannerId}`);
});

/**
 * Log scanner updates
 */
exports.onScannerUpdated = onDocumentUpdated("scanners/{scannerId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  const scannerId = event.params.scannerId;

  const changes = {};
  if (before.active !== after.active) changes.active = { from: before.active, to: after.active };
  if (before.venueId !== after.venueId) changes.venueId = { from: before.venueId, to: after.venueId };

  await createAuditLog(
    "scanner_updated",
    "scanner",
    scannerId,
    after.updatedBy || "system",
    {
      email: after.email,
      changes
    }
  );

  console.log(`Audit log created for scanner update: ${scannerId}`);
});

/**
 * Log scanner deletion
 */
exports.onScannerDeleted = onDocumentDeleted("scanners/{scannerId}", async (event) => {
  const scanner = event.data.data();
  const scannerId = event.params.scannerId;

  await createAuditLog(
    "scanner_deleted",
    "scanner",
    scannerId,
    "system",
    {
      email: scanner.email,
      name: scanner.name
    }
  );

  console.log(`Audit log created for scanner deletion: ${scannerId}`);
});

/**
 * Log event deletion
 */
exports.onEventDeleted = onDocumentDeleted("events/{eventId}", async (event) => {
  const eventData = event.data.data();
  const eventId = event.params.eventId;

  await createAuditLog(
    "event_deleted",
    "event",
    eventId,
    "system",
    {
      name: eventData.name,
      venueId: eventData.venueId,
      ticketsSold: eventData.ticketsSold || 0
    }
  );

  console.log(`Audit log created for event deletion: ${eventId}`);
});

/**
 * Log ticket refunds
 */
exports.onTicketRefunded = onDocumentUpdated("tickets/{ticketId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();

  // Only log if status changed to refunded
  if (before.status !== 'refunded' && after.status === 'refunded') {
    const ticketId = event.params.ticketId;

    await createAuditLog(
      "ticket_refunded",
      "ticket",
      ticketId,
      "system",
      {
        userId: after.userId,
        eventId: after.eventId,
        eventName: after.eventName,
        amount: after.totalPrice
      }
    );

    console.log(`Audit log created for ticket refund: ${ticketId}`);
  }
});
