export const EVENT_STATUS_OPTIONS = [
  { value: "draft", label: "Draft" },
  { value: "scheduled", label: "Scheduled" },
  { value: "active", label: "Active" },
  { value: "soldOut", label: "Sold Out" },
  { value: "completed", label: "Completed" },
  { value: "cancelled", label: "Cancelled" },
];

export const EVENT_CATEGORY_OPTIONS = [
  { value: "music", label: "Music" },
  { value: "nightlife", label: "Nightlife" },
  { value: "wellness", label: "Wellness" },
  { value: "arts", label: "Arts & Culture" },
  { value: "community", label: "Community" },
  { value: "food", label: "Food & Drink" },
  { value: "other", label: "Other" },
];

export const EVENT_TAG_OPTIONS = [
  "techno",
  "house",
  "garage",
  "drum-and-bass",
  "bass",
  "live",
  "comedy",
  "wellness",
  "art",
  "burner",
];

export const SCANNER_ROLE = "scanner" as const;

export type EventStatus = (typeof EVENT_STATUS_OPTIONS)[number]["value"];
