import { supabase } from "@/lib/supabase";
import { movePastEventsToFutureAction, simulateEventStartingSoonAction } from "@/lib/debug-actions";

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

// Delegate to server action
export async function movePastEventsToFuture() {
  return movePastEventsToFutureAction();
}

// Delegate to server action
export async function simulateEventStartingSoon() {
  return simulateEventStartingSoonAction();
}
