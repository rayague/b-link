import puppeteer from 'puppeteer';

// Emulator endpoints
const AUTH_HOST = '127.0.0.1';
const AUTH_PORT = 9099;
const FIRESTORE_HOST = '127.0.0.1';
const FIRESTORE_PORT = 8080;

const firebaseConfig = {
  apiKey: "fake",
  authDomain: "localhost",
  projectId: "b-link-local",
};

const html = `
<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <title>Firebase Emulator Client Smoke</title>
  <script type="module">
    import { initializeApp } from 'https://www.gstatic.com/firebasejs/9.22.0/firebase-app.js';
    import { getAuth, signInAnonymously, connectAuthEmulator } from 'https://www.gstatic.com/firebasejs/9.22.0/firebase-auth.js';
    import { getFirestore, doc, setDoc, getDoc, connectFirestoreEmulator } from 'https://www.gstatic.com/firebasejs/9.22.0/firebase-firestore.js';

    (async () => {
      try {
        const app = initializeApp(${JSON.stringify(firebaseConfig)});
        const auth = getAuth(app);
        connectAuthEmulator(auth, 'http://${AUTH_HOST}:${AUTH_PORT}');
        const db = getFirestore(app);
        connectFirestoreEmulator(db, '${FIRESTORE_HOST}', ${FIRESTORE_PORT});

        const cred = await signInAnonymously(auth);
        const uid = cred.user.uid;
        const ref = doc(db, 'profiles', uid);
        const data = {
          name: 'Emulator Smoke',
          birthDate: '1990-01-01',
          displayName: 'Emulator Smoke',
          lastSyncedAt: new Date().toISOString()
        };
        await setDoc(ref, data);
        const got = await getDoc(ref);
        window.__SMOKE_RESULT = { ok: true, uid, data: got.exists() ? got.data() : null };
      } catch (err) {
        window.__SMOKE_RESULT = { ok: false, error: (err && err.message) || String(err) };
      }
    })();
  </script>
</head>
<body>
  <h1>Firebase emulator client smoke test running...</h1>
</body>
</html>
`;

(async () => {
  const browser = await puppeteer.launch({ args: ['--no-sandbox','--disable-setuid-sandbox'] });
  const page = await browser.newPage();
  page.setDefaultTimeout(20000);
  await page.goto(`data:text/html,${encodeURIComponent(html)}`);
  try {
    await page.waitForFunction(() => window.__SMOKE_RESULT !== undefined, { timeout: 20000 });
    const result = await page.evaluate(() => window.__SMOKE_RESULT);
    console.log('EMULATOR SMOKE RESULT:', result);
    if (result.ok) process.exit(0);
    else process.exit(2);
  } catch (e) {
    console.error('Timed out waiting for smoke result', e && e.stack ? e.stack : e);
    process.exit(3);
  } finally {
    await browser.close();
  }
})();
