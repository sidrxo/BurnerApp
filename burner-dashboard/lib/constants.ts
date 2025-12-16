export const EVENT_STATUS_OPTIONS = [
  { value: "draft", label: "Draft" },
  { value: "scheduled", label: "Scheduled" },
  { value: "active", label: "Active" },
  { value: "soldOut", label: "Sold Out" },
  { value: "completed", label: "Completed" },
  { value: "cancelled", label: "Cancelled" },
];

export const SCANNER_ROLE = "scanner" as const;

export type EventStatus = (typeof EVENT_STATUS_OPTIONS)[number]["value"];
