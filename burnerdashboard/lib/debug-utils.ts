import { getDebugInfoAction, movePastEventsToFutureAction, simulateEventStartingSoonAction } from "@/lib/debug-actions";

// Delegate to server action
export async function getDebugInfo() {
  return getDebugInfoAction();
}

// Delegate to server action
export async function movePastEventsToFuture() {
  return movePastEventsToFutureAction();
}

// Delegate to server action
export async function simulateEventStartingSoon() {
  return simulateEventStartingSoonAction();
}
