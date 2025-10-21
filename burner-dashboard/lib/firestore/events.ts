import {
  db,
  collection,
  doc,
  addDoc,
  updateDoc,
  deleteDoc,
  onSnapshot,
  query,
  orderBy,
  serverTimestamp
} from "@/lib/firebase";
import { Timestamp, type QueryDocumentSnapshot } from "firebase/firestore";
import type { EventPayload, EventRecord, EventTag, FirestoreEvent } from "@/lib/types";
import { mapTimestampToDate, toTimestamp } from "./utils";

const eventsCollection = collection(db, "events");
const tagsCollection = collection(db, "eventTags");

function mapEvent(docSnapshot: QueryDocumentSnapshot<FirestoreEvent>): EventRecord {
  const data = docSnapshot.data();
  return {
    id: docSnapshot.id,
    name: data.name,
    venueName: data.venueName,
    venueId: data.venueId ?? null,
    price: data.price ?? 0,
    maxTickets: data.maxTickets ?? 0,
    ticketsSold: data.ticketsSold ?? 0,
    startTime: mapTimestampToDate(data.startTime),
    endTime: mapTimestampToDate(data.endTime),
    imageUrl: data.imageUrl ?? null,
    description: data.description ?? null,
    status: data.status ?? null,
    category: data.category ?? null,
    tagId: data.tagId ?? null,
    tagName: data.tagName ?? data.tags?.[0] ?? null,
    isFeatured: data.isFeatured ?? false,
    organizerId: data.organizerId ?? null,
    createdAt: mapTimestampToDate(data.createdAt),
    updatedAt: mapTimestampToDate(data.updatedAt)
  };
}

function buildEventWritePayload(
  payload: EventPayload,
  existing?: EventRecord
) {
  const now = serverTimestamp();
  const base: Record<string, unknown> = {
    name: payload.name,
    venueName: payload.venueName,
    venueId: payload.venueId ?? null,
    price: Number(payload.price ?? 0),
    maxTickets: Number(payload.maxTickets ?? 0),
    startTime: toTimestamp(payload.startTime),
    endTime: toTimestamp(payload.endTime),
    imageUrl: payload.imageUrl ?? null,
    description: payload.description ?? null,
    status: payload.status ?? null,
    category: payload.category ?? null,
    tagId: payload.tagId ?? null,
    tagName: payload.tagName ?? null,
    tags: payload.tagName ? [payload.tagName] : [],
    isFeatured: payload.isFeatured ?? false,
    organizerId: existing?.organizerId ?? null,
    updatedAt: now
  };

  if (existing?.ticketsSold !== undefined) {
    base.ticketsSold = existing.ticketsSold;
  } else {
    base.ticketsSold = 0;
  }

  if (!existing) {
    base.createdAt = now;
  }

  return base;
}

export function listenToEvents(
  callback: (events: EventRecord[]) => void,
  onError?: (error: Error) => void
) {
  const q = query(eventsCollection, orderBy("startTime", "asc"));
  return onSnapshot(
    q,
    (snapshot) => {
      const events = snapshot.docs.map((docSnapshot) =>
        mapEvent(docSnapshot as QueryDocumentSnapshot<FirestoreEvent>)
      );
      callback(events);
    },
    (error) => {
      onError?.(error as Error);
    }
  );
}

export async function createEvent(payload: EventPayload) {
  const data = buildEventWritePayload(payload);
  await addDoc(eventsCollection, data);
}

export async function updateEvent(id: string, payload: EventPayload, existing: EventRecord) {
  const data = buildEventWritePayload(payload, existing);
  const ref = doc(eventsCollection, id);
  await updateDoc(ref, data);
}

export async function deleteEvent(id: string) {
  const ref = doc(eventsCollection, id);
  await deleteDoc(ref);
}

type FirestoreTagDoc = QueryDocumentSnapshot<
  Omit<EventTag, "id"> & {
    archived?: boolean;
    sortOrder?: number | null;
    createdAt?: Timestamp | null;
    updatedAt?: Timestamp | null;
  }
>;

function mapTag(docSnapshot: FirestoreTagDoc): EventTag {
  const data = docSnapshot.data();
  return {
    id: docSnapshot.id,
    name: data.name,
    color: data.color ?? null,
    description: data.description ?? null,
    sortOrder: data.sortOrder ?? null,
    archived: data.archived ?? false
  };
}

export function listenToTags(
  callback: (tags: EventTag[]) => void,
  onError?: (error: Error) => void
) {
  const q = query(tagsCollection, orderBy("sortOrder", "asc"));
  return onSnapshot(
    q,
    (snapshot) => {
      const tags = snapshot.docs.map((docSnapshot) =>
        mapTag(docSnapshot as FirestoreTagDoc)
      );
      callback(tags);
    },
    (error) => onError?.(error as Error)
  );
}

export async function createTag(tag: Pick<EventTag, "name" | "color" | "description">) {
  const now = serverTimestamp();
  await addDoc(tagsCollection, {
    name: tag.name,
    color: tag.color ?? null,
    description: tag.description ?? null,
    sortOrder: Date.now(),
    archived: false,
    createdAt: now,
    updatedAt: now
  });
}

export async function updateTag(id: string, updates: Partial<EventTag>) {
  const ref = doc(tagsCollection, id);
  const payload: Record<string, unknown> = {
    ...updates,
    updatedAt: serverTimestamp()
  };
  await updateDoc(ref, payload);
}

export async function archiveTag(id: string, archived = true) {
  await updateTag(id, { archived });
}
