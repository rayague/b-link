# Emulator-based E2E smoke test (local / CI)

This document explains how to run the headless client smoke test against the Firebase emulators locally and how the CI job is configured.

Local quick start

1. Install firebase-tools and Puppeteer prerequisites on Windows (PowerShell / cmd):

```powershell
npm install -g firebase-tools
```

2. Start the emulators (from repo root):

```cmd
firebase emulators:start --only auth,firestore
```

3. In another terminal run the emulator smoke test (this uses Puppeteer and the Web SDK):

```cmd
node tool/client_smoke_emulator_puppet.js
```

CI notes

- The workflow `.github/workflows/ci.yml` starts the emulators in background and then runs `tool/client_smoke_emulator_puppet.js`.
- The workflow uses `sudo apt-get` to ensure Puppeteer dependencies are present on the ubuntu runner.

Cloud Functions

- If you want to deploy the Cloud Function `functions/index.js`, run:

```cmd
cd functions
npm install
firebase deploy --only functions --project b-link-3b2d5
```

Be careful: deploying functions requires billing-enabled or proper permissions on the target project.
