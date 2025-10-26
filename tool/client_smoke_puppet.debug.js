import puppeteer from 'puppeteer';

console.log('DEBUG: client_smoke_puppet.debug.js starting');

const firebaseConfig = {
  apiKey: "AIzaSyDAWMiZq75sM5Qx-iDfbd54X4faM1xOma0",
  authDomain: "b-link-3b2d5.firebaseapp.com",
  projectId: "b-link-3b2d5",
  storageBucket: "b-link-3b2d5.firebasestorage.app",
  messagingSenderId: "1086266729781",
  appId: "1:1086266729781:web:cac79a6d43b106d35b187c",
  measurementId: "G-GJL437S33G"
};

const html = `
<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <title>Firebase Client Smoke - DEBUG</title>
  <script type="module">
    import { initializeApp } from 'https://www.gstatic.com/firebasejs/9.22.0/firebase-app.js';
    import { getAuth, signInAnonymously } from 'https://www.gstatic.com/firebasejs/9.22.0/firebase-auth.js';
    import { getFirestore, doc, setDoc, getDoc } from 'https://www.gstatic.com/firebasejs/9.22.0/firebase-firestore.js';

    (async () => {
      try {
        const app = initializeApp(${JSON.stringify(firebaseConfig)});
        const auth = getAuth(app);
        const db = getFirestore(app);

        const cred = await signInAnonymously(auth);
        const uid = cred.user.uid;
        const id = uid;
  const refPath = 'profiles/' + id;
        const ref = doc(db, 'profiles', id);
        const data = {
          name: 'Smoke Browser (debug)',
          birthDate: '1990-01-01',
          displayName: 'Smoke Browser',
          lastSyncedAt: new Date().toISOString()
        };

        // Log debug info to the page console (Puppeteer will capture)
  console.log('DEBUG: signing-in ok; uid=', uid);
  console.log('DEBUG: about to write', refPath, JSON.stringify(data));

        await setDoc(ref, data);
  console.log('DEBUG: setDoc succeeded for', refPath, JSON.stringify(data));
        const got = await getDoc(ref);
        window.__SMOKE_RESULT = { ok: true, uid, refPath, data: got.exists() ? got.data() : null };
      } catch (err) {
        // capture more details from the SDK error
        const errObj = {
          message: err && err.message ? err.message : String(err),
          name: err && err.name ? err.name : undefined,
          code: err && err.code ? err.code : undefined,
          stack: err && err.stack ? err.stack : undefined
        };
        console.error('DEBUG: caught error', errObj);
        window.__SMOKE_RESULT = { ok: false, error: errObj };
      }
    })();
  </script>
</head>
<body>
  <h1>Firebase client smoke test (debug) running...</h1>
</body>
</html>
`;

(async () => {
  const browser = await puppeteer.launch({ args: ['--no-sandbox','--disable-setuid-sandbox'] });
  const page = await browser.newPage();
  // pipe page console messages to node console
  page.on('console', msg => {
    const text = msg.text();
    console.log('PAGE LOG>', text);
  });

  // Increase timeout
  page.setDefaultTimeout(30000);
  await page.goto(`data:text/html,${encodeURIComponent(html)}`);

  // Wait until window.__SMOKE_RESULT is set
  try {
    await page.waitForFunction(() => window.__SMOKE_RESULT !== undefined, { timeout: 20000 });
    const result = await page.evaluate(() => window.__SMOKE_RESULT);
    console.log('SMOKE RESULT:', result);
    if (result.ok) process.exit(0);
    else process.exit(2);
  } catch (e) {
    console.error('Timed out waiting for smoke result', e && e.stack ? e.stack : e);
    process.exit(3);
  } finally {
    await browser.close();
  }
})();
