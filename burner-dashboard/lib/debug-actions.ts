"use server";

import { supabaseAdmin } from "./supabase-server";

export async function movePastEventsToFutureAction() {
  try {
    const now = new Date();
    const futureDate = new Date(now);
    futureDate.setDate(futureDate.getDate() + 7); // Move 7 days into the future

    // Get all past events using admin client
    const { data: pastEvents, error: fetchError } = await supabaseAdmin
      .from('events')
      .select('*')
      .lt('end_time', now.toISOString());

    if (fetchError) {
      console.error("Error fetching past events:", fetchError);
      throw fetchError;
    }

    if (!pastEvents || pastEvents.length === 0) {
      return { success: true, count: 0 };
    }

    // Update each event
    const updates = pastEvents.map(event => {
      const originalStart = new Date(event.start_time);
      const originalEnd = new Date(event.end_time);
      const duration = originalEnd.getTime() - originalStart.getTime();

      const newStart = new Date(futureDate);
      // Preserve the original time of day
      newStart.setHours(originalStart.getHours());
      newStart.setMinutes(originalStart.getMinutes());
      newStart.setSeconds(originalStart.getSeconds());

      const newEnd = new Date(newStart.getTime() + duration);

      return {
        id: event.id,
        start_time: newStart.toISOString(),
        end_time: newEnd.toISOString(),
      };
    });

    // Update all events in parallel using admin client
    const updatePromises = updates.map(({ id, start_time, end_time }) =>
      supabaseAdmin
        .from('events')
        .update({ start_time, end_time })
        .eq('id', id)
    );

    const results = await Promise.all(updatePromises);

    // Check if any updates failed
    const failedUpdates = results.filter(result => result.error);
    if (failedUpdates.length > 0) {
      console.error("Some updates failed:", failedUpdates);
      throw new Error(`${failedUpdates.length} event updates failed`);
    }

    return {
      success: true,
      count: pastEvents.length,
    };
  } catch (error) {
    console.error("Error moving past events:", error);
    return {
      success: false,
      count: 0,
      error: error instanceof Error ? error.message : "Unknown error",
    };
  }
}

export async function simulateEventStartingSoonAction() {
  try {
    // Get the soonest event (by start_time) using admin client
    const { data: events, error: fetchError } = await supabaseAdmin
      .from('events')
      .select('*')
      .order('start_time', { ascending: true })
      .limit(1);

    if (fetchError) {
      console.error("Error fetching events:", fetchError);
      throw fetchError;
    }

    if (!events || events.length === 0) {
      return {
        success: false,
        error: "No events found in the database",
      };
    }

    const soonestEvent = events[0];

    // Set event to start in 5 minutes
    const now = new Date();
    const startTime = new Date(now.getTime() + 5 * 60 * 1000); // 5 minutes from now
    const endTime = new Date(now.getTime() + 20 * 60 * 1000);  // 20 minutes from now (15 min duration)

    // Update the event using admin client
    const { error: updateError } = await supabaseAdmin
      .from('events')
      .update({
        start_time: startTime.toISOString(),
        end_time: endTime.toISOString(),
      })
      .eq('id', soonestEvent.id);

    if (updateError) {
      console.error("Error updating event:", updateError);
      throw updateError;
    }

    return {
      success: true,
      eventName: soonestEvent.name || soonestEvent.title || "Unnamed Event",
      eventId: soonestEvent.id,
    };
  } catch (error) {
    console.error("Error simulating event:", error);
    return {
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    };
  }
}
