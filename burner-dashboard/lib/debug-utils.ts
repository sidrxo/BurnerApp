import { supabase } from "@/lib/supabase";

export async function getDebugInfo() {
  try {
    // Get total events count
    const { count: totalEvents, error: totalError } = await supabase
      .from('events')
      .select('*', { count: 'exact', head: true });

    if (totalError) throw totalError;

    // Get past events count (events that have already ended)
    const now = new Date().toISOString();
    const { count: pastEvents, error: pastError } = await supabase
      .from('events')
      .select('*', { count: 'exact', head: true })
      .lt('end_time', now);

    if (pastError) throw pastError;

    // Get future events count (events that haven't ended yet)
    const { count: futureEvents, error: futureError } = await supabase
      .from('events')
      .select('*', { count: 'exact', head: true })
      .gte('end_time', now);

    if (futureError) throw futureError;

    // Get total venues count
    const { count: totalVenues, error: venuesError } = await supabase
      .from('venues')
      .select('*', { count: 'exact', head: true });

    if (venuesError) throw venuesError;

    return {
      totalEvents: totalEvents || 0,
      pastEvents: pastEvents || 0,
      futureEvents: futureEvents || 0,
      totalVenues: totalVenues || 0,
    };
  } catch (error) {
    console.error("Error getting debug info:", error);
    return {
      totalEvents: 0,
      pastEvents: 0,
      futureEvents: 0,
      totalVenues: 0,
    };
  }
}

export async function movePastEventsToFuture() {
  try {
    const now = new Date();
    const futureDate = new Date(now);
    futureDate.setDate(futureDate.getDate() + 7); // Move 7 days into the future

    // Get all past events
    const { data: pastEvents, error: fetchError } = await supabase
      .from('events')
      .select('*')
      .lt('end_time', now.toISOString());

    if (fetchError) throw fetchError;

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

    // Update all events in parallel
    const updatePromises = updates.map(({ id, start_time, end_time }) =>
      supabase
        .from('events')
        .update({ start_time, end_time })
        .eq('id', id)
    );

    await Promise.all(updatePromises);

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

export async function simulateEventStartingSoon() {
  try {
    // Get the soonest event (by start_time)
    const { data: events, error: fetchError } = await supabase
      .from('events')
      .select('*')
      .order('start_time', { ascending: true })
      .limit(1);

    if (fetchError) throw fetchError;

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

    // Update the event
    const { error: updateError } = await supabase
      .from('events')
      .update({
        start_time: startTime.toISOString(),
        end_time: endTime.toISOString(),
      })
      .eq('id', soonestEvent.id);

    if (updateError) throw updateError;

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
