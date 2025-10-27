import puppeteer from 'puppeteer';

// Allow overriding via env for flexibility in CI
const AUTH_HOST = process.env.EMULATOR_AUTH_HOST || '127.0.0.1';
const AUTH_PORT = process.env.EMULATOR_AUTH_PORT || 9099;
const FIRESTORE_HOST = process.env.EMULATOR_FIRESTORE_HOST || '127.0.0.1';
const FIRESTORE_PORT = process.env.EMULATOR_FIRESTORE_PORT || 8080;

const firebaseConfig = {
  apiKey: 'fake',
  authDomain: 'localhost',
  projectId: process.env.EMULATOR_PROJECT_ID || 'b-link-local',
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
        connectAuthEmulator(auth, 'http://${AUTH_HOST}:${AUTH_PORT}', { disableWarnings: true });
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
        const errObj = { message: err && err.message ? err.message : String(err), name: err && err.name, code: err && err.code };
        console.error('CLIENT ERROR', errObj);
        window.__SMOKE_RESULT = { ok: false, error: errObj };
      }
    })();
  </script>
</head>
<body>
  <h1>Firebase emulator client smoke test running...</h1>
</body>
</html>
`;

// Wait until the emulator ports are accepting connections to avoid race conditions
import net from 'net';

async function waitForPort(host, port, attempts = 20, delayMs = 300) {
  for (let i = 0; i < attempts; i++) {
    try {
      await new Promise((res, rej) => {
        const s = net.createConnection({ host, port }, () => {
          s.destroy();
          res();
        });
        s.on('error', err => {
          s.destroy();
          rej(err);
        });
      });
      return true;
    } catch (e) {
      await new Promise(r => setTimeout(r, delayMs));
    }
  }
  return false;
}

(async () => {
  const authReady = await waitForPort(AUTH_HOST, AUTH_PORT, 30, 300);
  const fsReady = await waitForPort(FIRESTORE_HOST, FIRESTORE_PORT, 30, 300);
  if (!authReady || !fsReady) {
    console.error('Emulator ports not ready: authReady=', authReady, 'firestoreReady=', fsReady);
    process.exit(4);
  }

  const browser = await puppeteer.launch({ args: ['--no-sandbox','--disable-setuid-sandbox'] });
  const page = await browser.newPage();
  page.on('console', msg => console.log('PAGE LOG>', msg.text()));
  page.setDefaultTimeout(30000);
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
