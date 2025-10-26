import { initializeApp } from 'firebase/app';
import { getAuth, signInAnonymously } from 'firebase/auth';
import { getFirestore, doc, setDoc, getDoc } from 'firebase/firestore';

// Inline config copied from firebaseConfig.js
const firebaseConfig = {
  apiKey: "AIzaSyDAWMiZq75sM5Qx-iDfbd54X4faM1xOma0",
  authDomain: "b-link-3b2d5.firebaseapp.com",
  projectId: "b-link-3b2d5",
  storageBucket: "b-link-3b2d5.firebasestorage.app",
  messagingSenderId: "1086266729781",
  appId: "1:1086266729781:web:cac79a6d43b106d35b187c",
  measurementId: "G-GJL437S33G"
};

async function main() {
  try {
    const app = initializeApp(firebaseConfig);
    const auth = getAuth(app);
    const db = getFirestore(app);

    console.log('Signing in anonymously...');
    const cred = await signInAnonymously(auth);
    const user = cred.user;
    console.log('Signed in. uid=', user.uid);

  // Firestore rules require document ID == auth.uid for profiles, so write under the user uid
  const id = user.uid;
  const ref = doc(db, 'profiles', id);
    const data = {
      name: 'Smoke Client',
      birthDate: '1990-01-01',
      displayName: 'Smoke Client',
      lastSyncedAt: new Date().toISOString()
    };

    console.log('Writing document', ref.path);
    await setDoc(ref, data);
    console.log('Write complete. Reading back...');
    const got = await getDoc(ref);
    if (!got.exists()) {
      console.error('Document not found after write');
      process.exit(4);
    }
    console.log('Read OK:', JSON.stringify(got.data(), null, 2));
    process.exit(0);
  } catch (err) {
    console.error('Smoke client failed:', err && err.stack ? err.stack : err);
    process.exit(2);
  }
}

main();
