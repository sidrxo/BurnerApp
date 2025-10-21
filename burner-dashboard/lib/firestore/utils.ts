import { Timestamp } from "firebase/firestore";

export function mapTimestampToDate(value?: Timestamp | null) {
  if (!value) return null;
  return value.toDate();
}

export function toTimestamp(date: Date | null | undefined) {
  if (!date) return null;
  return Timestamp.fromDate(date);
}
