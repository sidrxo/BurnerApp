import { initializeApp, getApps, getApp } from "firebase/app";
import {
  getAuth,
  browserLocalPersistence,
  setPersistence,
  type Auth
} from "firebase/auth";
import {
  getFirestore,
  collection,
  doc,
  getDocs,
  addDoc,
  updateDoc,
  deleteDoc,
  onSnapshot,
  query,
  orderBy,
  serverTimestamp,
  type Firestore,
  type DocumentData,
  type QueryDocumentSnapshot,
  Timestamp
} from "firebase/firestore";
import { getFunctions, httpsCallable } from "firebase/functions";

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
};

function createFirebaseApp() {
  if (!firebaseConfig.projectId) {
    throw new Error("Missing Firebase configuration. Check environment variables.");
  }

  if (!getApps().length) {
    return initializeApp(firebaseConfig);
  }

  return getApp();
}

export const firebaseApp = createFirebaseApp();
export const db = getFirestore(firebaseApp);
export const functions = getFunctions(firebaseApp, "us-central1");

export function callable<T = unknown, R = unknown>(name: string) {
  return httpsCallable<T, R>(functions, name);
}

export async function getClientAuth(): Promise<Auth> {
  const auth = getAuth(firebaseApp);
  if (typeof window !== "undefined") {
    await setPersistence(auth, browserLocalPersistence);
  }
  return auth;
}

export {
  collection,
  doc,
  getDocs,
  addDoc,
  updateDoc,
  deleteDoc,
  onSnapshot,
  query,
  orderBy,
  serverTimestamp,
  Timestamp,
  type Firestore,
  type DocumentData,
  type QueryDocumentSnapshot
};
