const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { requireAuth, requireSiteAdmin } = require("../shared/permissions");

const db = getFirestore();

/**
 * Get all tags
 * Available to all authenticated users
 */
exports.getTags = onCall(async (request) => {
  try {
    // Require authentication
    requireAuth(request);

    const tagsSnapshot = await db
      .collection("tags")
      .orderBy("order", "asc")
      .orderBy("name", "asc")
      .get();

    const tags = tagsSnapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    return {
      success: true,
      tags,
    };
  } catch (error) {
    console.error("Error getting tags:", error);

    if (error instanceof HttpsError) {
      throw error;
    }

    throw new HttpsError(
      "internal",
      "Failed to get tags",
      error.message
    );
  }
});

/**
 * Create a new tag
 * Restricted to site admins only
 */
exports.createTag = onCall(async (request) => {
  try {
    // Require site admin
    requireSiteAdmin(request);

    const { name, description, color } = request.data;

    // Validate input
    if (!name || typeof name !== "string") {
      throw new HttpsError("invalid-argument", "Tag name is required");
    }

    const trimmedName = name.trim();

    if (trimmedName.length === 0) {
      throw new HttpsError("invalid-argument", "Tag name cannot be empty");
    }

    // Check if tag with same name already exists (case-insensitive)
    const existingTags = await db
      .collection("tags")
      .where("nameLowercase", "==", trimmedName.toLowerCase())
      .get();

    if (!existingTags.empty) {
      throw new HttpsError(
        "already-exists",
        "A tag with this name already exists"
      );
    }

    // Get the highest order value
    const tagsSnapshot = await db
      .collection("tags")
      .orderBy("order", "desc")
      .limit(1)
      .get();

    const maxOrder = tagsSnapshot.empty ? 0 : tagsSnapshot.docs[0].data().order || 0;

    // Create the tag
    const tagData = {
      name: trimmedName,
      nameLowercase: trimmedName.toLowerCase(),
      description: description?.trim() || null,
      color: color || null,
      order: maxOrder + 1,
      createdAt: FieldValue.serverTimestamp(),
      createdBy: request.auth.uid,
      updatedAt: FieldValue.serverTimestamp(),
      active: true,
    };

    const tagRef = await db.collection("tags").add(tagData);

    return {
      success: true,
      message: `Tag "${trimmedName}" created successfully`,
      tagId: tagRef.id,
    };
  } catch (error) {
    console.error("Error creating tag:", error);

    if (error instanceof HttpsError) {
      throw error;
    }

    throw new HttpsError(
      "internal",
      "Failed to create tag",
      error.message
    );
  }
});

/**
 * Update an existing tag
 * Restricted to site admins only
 */
exports.updateTag = onCall(async (request) => {
  try {
    // Require site admin
    requireSiteAdmin(request);

    const { tagId, updates } = request.data;

    // Validate input
    if (!tagId || typeof tagId !== "string") {
      throw new HttpsError("invalid-argument", "Tag ID is required");
    }

    if (!updates || typeof updates !== "object") {
      throw new HttpsError("invalid-argument", "Updates object is required");
    }

    // Get the tag document
    const tagRef = db.collection("tags").doc(tagId);
    const tagDoc = await tagRef.get();

    if (!tagDoc.exists) {
      throw new HttpsError("not-found", "Tag not found");
    }

    // Build the update object
    const updateData = {
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: request.auth.uid,
    };

    // Update name if provided
    if (updates.name !== undefined) {
      if (typeof updates.name !== "string") {
        throw new HttpsError("invalid-argument", "Tag name must be a string");
      }

      const trimmedName = updates.name.trim();

      if (trimmedName.length === 0) {
        throw new HttpsError("invalid-argument", "Tag name cannot be empty");
      }

      // Check if another tag with same name exists (case-insensitive)
      const existingTags = await db
        .collection("tags")
        .where("nameLowercase", "==", trimmedName.toLowerCase())
        .get();

      const hasDuplicate = existingTags.docs.some(doc => doc.id !== tagId);

      if (hasDuplicate) {
        throw new HttpsError(
          "already-exists",
          "A tag with this name already exists"
        );
      }

      updateData.name = trimmedName;
      updateData.nameLowercase = trimmedName.toLowerCase();
    }

    // Update description if provided
    if (updates.description !== undefined) {
      updateData.description = updates.description?.trim() || null;
    }

    // Update color if provided
    if (updates.color !== undefined) {
      updateData.color = updates.color || null;
    }

    // Update order if provided
    if (updates.order !== undefined) {
      if (typeof updates.order !== "number") {
        throw new HttpsError("invalid-argument", "Order must be a number");
      }
      updateData.order = updates.order;
    }

    // Update active status if provided
    if (updates.active !== undefined) {
      if (typeof updates.active !== "boolean") {
        throw new HttpsError("invalid-argument", "Active must be a boolean");
      }
      updateData.active = updates.active;
    }

    // Update the tag
    await tagRef.update(updateData);

    return {
      success: true,
      message: "Tag updated successfully",
    };
  } catch (error) {
    console.error("Error updating tag:", error);

    if (error instanceof HttpsError) {
      throw error;
    }

    throw new HttpsError(
      "internal",
      "Failed to update tag",
      error.message
    );
  }
});

/**
 * Delete a tag
 * Restricted to site admins only
 */
exports.deleteTag = onCall(async (request) => {
  try {
    // Require site admin
    requireSiteAdmin(request);

    const { tagId } = request.data;

    // Validate input
    if (!tagId || typeof tagId !== "string") {
      throw new HttpsError("invalid-argument", "Tag ID is required");
    }

    // Get the tag document
    const tagRef = db.collection("tags").doc(tagId);
    const tagDoc = await tagRef.get();

    if (!tagDoc.exists) {
      throw new HttpsError("not-found", "Tag not found");
    }

    const tagData = tagDoc.data();
    const tagName = tagData.name;

    // Check if tag is used in any events
    const eventsWithTag = await db
      .collection("events")
      .where("tags", "array-contains", tagName)
      .limit(1)
      .get();

    if (!eventsWithTag.empty) {
      throw new HttpsError(
        "failed-precondition",
        `Cannot delete tag "${tagName}" because it is used in ${eventsWithTag.size} or more events. Please remove it from all events first.`
      );
    }

    // Delete the tag
    await tagRef.delete();

    return {
      success: true,
      message: `Tag "${tagName}" deleted successfully`,
    };
  } catch (error) {
    console.error("Error deleting tag:", error);

    if (error instanceof HttpsError) {
      throw error;
    }

    throw new HttpsError(
      "internal",
      "Failed to delete tag",
      error.message
    );
  }
});

/**
 * Reorder tags
 * Restricted to site admins only
 */
exports.reorderTags = onCall(async (request) => {
  try {
    // Require site admin
    requireSiteAdmin(request);

    const { tagOrders } = request.data;

    // Validate input
    if (!Array.isArray(tagOrders)) {
      throw new HttpsError("invalid-argument", "Tag orders must be an array");
    }

    // Batch update the orders
    const batch = db.batch();

    for (const { tagId, order } of tagOrders) {
      if (!tagId || typeof order !== "number") {
        throw new HttpsError(
          "invalid-argument",
          "Each tag order must have tagId and order"
        );
      }

      const tagRef = db.collection("tags").doc(tagId);
      batch.update(tagRef, {
        order,
        updatedAt: FieldValue.serverTimestamp(),
        updatedBy: request.auth.uid,
      });
    }

    await batch.commit();

    return {
      success: true,
      message: "Tags reordered successfully",
    };
  } catch (error) {
    console.error("Error reordering tags:", error);

    if (error instanceof HttpsError) {
      throw error;
    }

    throw new HttpsError(
      "internal",
      "Failed to reorder tags",
      error.message
    );
  }
});
