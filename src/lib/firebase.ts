import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';
import { getAuth, setPersistence, browserLocalPersistence } from 'firebase/auth';

const firebaseConfig = {
  apiKey: "AIzaSyDT_MJQFqPiRXwqJzRJN_VdNR9qF-1ki_s",
  authDomain: "xerolinux-6e564.firebaseapp.com",
  projectId: "xerolinux-6e564",
  storageBucket: "xerolinux-6e564.appspot.com",
  measurementId: "G-XTMB3XQHP4",
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
export const auth = getAuth(app);

// Force session persistence across page reloads / tabs / restarts.
// Default is already local, but setting explicitly guards against
// some browsers downgrading to in-memory under privacy modes.
if (typeof window !== 'undefined') {
  setPersistence(auth, browserLocalPersistence).catch(() => {});
}
