/**
 * Debug utilities for site administrators
 */

import { collection, getDocs, updateDoc, doc, Timestamp } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { toast } from "sonner";

/**
 * Moves all passed events to the future (for testing/demo purposes)
 * Only available to site administrators
 */
export async function movePastEventsToFuture(): Promise<{ success: boolean; count: number; error?: string }> {
  try {
    // Get all events
    const eventsSnapshot = await getDocs(collection(db, "events"));
    const now = new Date();
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(19, 0, 0, 0); // Set to 7 PM tomorrow

    let updatedCount = 0;
    const updatePromises: Promise<void>[] = [];

    eventsSnapshot.forEach((eventDoc) => {
      const data = eventDoc.data();
      const startTime = data.startTime?.toDate();
      const endTime = data.endTime?.toDate();

      // Check if event has passed
      if (startTime && startTime < now) {
        // Calculate how many days to add to move event to future
        const daysDiff = Math.ceil((now.getTime() - startTime.getTime()) / (1000 * 60 * 60 * 24));
        const daysToAdd = daysDiff + 7; // Add extra week to ensure it's in the future

        // Create new dates
        const newStartTime = new Date(startTime);
        newStartTime.setDate(newStartTime.getDate() + daysToAdd);

        const newEndTime = endTime ? new Date(endTime) : null;
        if (newEndTime) {
          newEndTime.setDate(newEndTime.getDate() + daysToAdd);
        }

        // Update the event
        const updateData: any = {
          startTime: Timestamp.fromDate(newStartTime),
          date: Timestamp.fromDate(newStartTime),
          updatedAt: Timestamp.now(),
        };

        if (newEndTime) {
          updateData.endTime = Timestamp.fromDate(newEndTime);
        }

        updatePromises.push(
          updateDoc(doc(db, "events", eventDoc.id), updateData)
        );
        updatedCount++;
      }
    });

    // Execute all updates
    await Promise.all(updatePromises);

    return {
      success: true,
      count: updatedCount,
    };
  } catch (error: any) {
    console.error("Error moving past events:", error);
    return {
      success: false,
      count: 0,
      error: error.message || "Failed to move past events",
    };
  }
}

/**
 * Simulates an event happening soon by setting the soonest event to start in 5 minutes
 * Only available to site administrators
 */
export async function simulateEventStartingSoon(): Promise<{ success: boolean; eventName?: string; error?: string }> {
  try {
    // Get all events
    const eventsSnapshot = await getDocs(collection(db, "events"));

    if (eventsSnapshot.empty) {
      return {
        success: false,
        error: "No events found in the database",
      };
    }

    // Find the soonest event (earliest start time)
    let soonestEvent: { id: string; name: string; startTime: Date } | null = null;

    eventsSnapshot.forEach((eventDoc) => {
      const data = eventDoc.data();
      const startTime = data.startTime?.toDate();

      if (startTime) {
        if (!soonestEvent || startTime < soonestEvent.startTime) {
          soonestEvent = {
            id: eventDoc.id,
            name: data.name || "Unnamed Event",
            startTime,
          };
        }
      }
    });

    if (!soonestEvent) {
      return {
        success: false,
        error: "No events with valid start times found",
      };
    }

    // Set start time to 5 minutes from now
    const now = new Date();
    const newStartTime = new Date(now.getTime() + 5 * 60 * 1000); // 5 minutes from now
    const newEndTime = new Date(newStartTime.getTime() + 10 * 60 * 1000); // 10 minutes after start (15 minutes from now)

    // Update the event
    await updateDoc(doc(db, "events", soonestEvent.id), {
      startTime: Timestamp.fromDate(newStartTime),
      endTime: Timestamp.fromDate(newEndTime),
      date: Timestamp.fromDate(newStartTime),
      updatedAt: Timestamp.now(),
    });

    return {
      success: true,
      eventName: soonestEvent.name,
    };
  } catch (error: any) {
    console.error("Error simulating event:", error);
    return {
      success: false,
      error: error.message || "Failed to simulate event",
    };
  }
}

/**
 * Get debug information about the database
 */
export async function getDebugInfo() {
  try {
    const eventsSnapshot = await getDocs(collection(db, "events"));
    const venuesSnapshot = await getDocs(collection(db, "venues"));
    const now = new Date();

    let pastEvents = 0;
    let futureEvents = 0;

    eventsSnapshot.forEach((doc) => {
      const data = doc.data();
      const startTime = data.startTime?.toDate();
      if (startTime) {
        if (startTime < now) {
          pastEvents++;
        } else {
          futureEvents++;
        }
      }
    });

    return {
      totalEvents: eventsSnapshot.size,
      pastEvents,
      futureEvents,
      totalVenues: venuesSnapshot.size,
    };
  } catch (error) {
    console.error("Error getting debug info:", error);
    return null;
  }
}
