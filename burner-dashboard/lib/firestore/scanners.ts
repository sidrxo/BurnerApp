import {
  db,
  collection,
  doc,
  updateDoc,
  onSnapshot,
  query,
  orderBy,
  serverTimestamp,
  callable
} from "@/lib/firebase";
import type { ScannerPayload, ScannerRecord, FirestoreScanner } from "@/lib/types";
import { mapTimestampToDate } from "./utils";
import type { QueryDocumentSnapshot } from "firebase/firestore";

const scannersCollection = collection(db, "scanners");
const createScannerCallable = callable<
  ScannerPayload & { venueName?: string | null },
  { success: boolean; message: string; scannerId?: string }
>("createScanner");
const setScannerStatusCallable = callable<
  { scannerId: string; active: boolean },
  { success: boolean }
>("setScannerStatus");
const deleteScannerCallable = callable<
  { scannerId: string },
  { success: boolean }
>("deleteScanner");

function mapScanner(docSnapshot: QueryDocumentSnapshot<FirestoreScanner>): ScannerRecord {
  const data = docSnapshot.data();
  return {
    id: docSnapshot.id,
    email: data.email,
    displayName: data.displayName,
    venueId: data.venueId ?? null,
    venueName: data.venueName ?? null,
    venues: data.venues ?? [],
    active: data.active ?? true,
    createdAt: mapTimestampToDate(data.createdAt),
    lastSignInAt: mapTimestampToDate(data.lastSignInAt),
    notes: data.notes ?? null
  };
}

export function listenToScanners(
  callback: (scanners: ScannerRecord[]) => void,
  onError?: (error: Error) => void
) {
  const q = query(scannersCollection, orderBy("createdAt", "desc"));
  return onSnapshot(
    q,
    (snapshot) => {
      const scanners = snapshot.docs.map((docSnapshot) =>
        mapScanner(docSnapshot as QueryDocumentSnapshot<FirestoreScanner>)
      );
      callback(scanners);
    },
    (error) => onError?.(error as Error)
  );
}

export async function createScanner(payload: ScannerPayload & { venueName?: string | null }) {
  const response = await createScannerCallable(payload);
  if (!response.data?.success) {
    throw new Error(response.data?.message ?? "Failed to create scanner");
  }
  return response.data;
}

export async function updateScanner(id: string, updates: Partial<ScannerPayload>) {
  const ref = doc(scannersCollection, id);
  const payload: Record<string, unknown> = {
    ...updates,
    updatedAt: serverTimestamp()
  };
  await updateDoc(ref, payload);
}

export async function setScannerActive(id: string, active: boolean) {
  await setScannerStatusCallable({ scannerId: id, active });
}

export async function deleteScanner(id: string) {
  await deleteScannerCallable({ scannerId: id });
}
