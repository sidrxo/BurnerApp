"use server";

import { supabaseAdmin } from "./supabase-server";

// Type definition for event data from database
type EventData = {
  id: string;
  name?: string;
  title?: string;
  start_time: string;
  end_time: string;
  [key: string]: any;
};

export async function getDebugInfoAction() {
  try {
    console.log('🔵 [Debug] Fetching debug info...');

    // Get total events count using admin client
    const { count: totalEvents, error: totalError } = await supabaseAdmin
      .from('events')
      .select('*', { count: 'exact', head: true });

    if (totalError) {
      console.error('❌ [Debug] Error fetching total events:', totalError);
      throw totalError;
    }

    // Get past events count (events that have already ended)
    const now = new Date().toISOString();
    const { count: pastEvents, error: pastError } = await supabaseAdmin
      .from('events')
      .select('*', { count: 'exact', head: true })
      .lt('end_time', now);

    if (pastError) {
      console.error('❌ [Debug] Error fetching past events:', pastError);
      throw pastError;
    }

    // Get future events count (events that haven't ended yet)
    const { count: futureEvents, error: futureError } = await supabaseAdmin
      .from('events')
      .select('*', { count: 'exact', head: true })
      .gte('end_time', now);

    if (futureError) {
      console.error('❌ [Debug] Error fetching future events:', futureError);
      throw futureError;
    }

    // Get total venues count
    const { count: totalVenues, error: venuesError } = await supabaseAdmin
      .from('venues')
      .select('*', { count: 'exact', head: true });

    if (venuesError) {
      console.error('❌ [Debug] Error fetching venues:', venuesError);
      throw venuesError;
    }

    console.log('✅ [Debug] Successfully fetched debug info:', {
      totalEvents,
      pastEvents,
      futureEvents,
      totalVenues
    });

    return {
      totalEvents: totalEvents || 0,
      pastEvents: pastEvents || 0,
      futureEvents: futureEvents || 0,
      totalVenues: totalVenues || 0,
    };
  } catch (error) {
    console.error("❌ [Debug] Error getting debug info:", error);
    // Return zeros instead of throwing to prevent page crashes
    return {
      totalEvents: 0,
      pastEvents: 0,
      futureEvents: 0,
      totalVenues: 0,
    };
  }
}

export async function movePastEventsToFutureAction() {
  try {
    console.log('🔵 [Debug] Starting move events to future...');
    const now = new Date();
    const futureDate = new Date(now);
    futureDate.setDate(futureDate.getDate() + 7); // Move 7 days into the future

    // Get all past events using admin client
    const { data: pastEvents, error: fetchError } = await supabaseAdmin
      .from('events')
      .select('*')
      .lt('end_time', now.toISOString())
      .returns<EventData[]>();

    if (fetchError) {
      console.error("❌ [Debug] Error fetching past events:", fetchError);
      throw fetchError;
    }

    if (!pastEvents || pastEvents.length === 0) {
      console.log('ℹ️ [Debug] No past events to move');
      return { success: true, count: 0 };
    }

    console.log(`🔵 [Debug] Found ${pastEvents.length} past events to move`);

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
        .update({ start_time, end_time } as any)
        .eq('id', id)
    );

    const results = await Promise.all(updatePromises);

    // Check if any updates failed
    const failedUpdates = results.filter(result => result.error);
    if (failedUpdates.length > 0) {
      console.error("❌ [Debug] Some updates failed:", failedUpdates);
      throw new Error(`${failedUpdates.length} event updates failed`);
    }

    console.log(`✅ [Debug] Successfully moved ${pastEvents.length} events to future`);

    return {
      success: true,
      count: pastEvents.length,
    };
  } catch (error) {
    console.error("❌ [Debug] Error moving past events:", error);
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
      .limit(1)
      .returns<EventData[]>();

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
      } as any)
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
