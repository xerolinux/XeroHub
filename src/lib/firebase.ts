import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';
import { getAuth } from 'firebase/auth';

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
