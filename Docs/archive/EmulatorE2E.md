# Running E2E against Firebase Emulator (Auth + Firestore)

This document shows how to run a quick end-to-end smoke test locally using the Firebase Emulator Suite.

Prerequisites
- Node.js (16+), npm
- Firebase CLI installed (`npm install -g firebase-tools`) and logged in (`firebase login`)
- The project directory (this repo)

What the scripts do
- `tool/run_emulator_e2p.ps1` starts the Auth and Firestore emulators, waits until they're ready, runs a headless browser client test that signs-in-anonymously and writes `profiles/{uid}` and reads it back, then shuts down the emulators.
- `tool/client_smoke_emulator_puppet.js` is a Puppeteer script that opens a headless Chromium, loads the Firebase Web SDK, connects to the emulators and performs the write/read.

How to run (PowerShell)
1. From repo root run:

```powershell
Set-Location D:\Projects\b_link
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\run_emulator_e2p.ps1
```

2. The script will print status and exit with code 0 on success, non-zero on failures. If the emulators fail to start, check `firebase emulators:start` manually to view logs.

Notes
- Emulator default ports: Firestore 8080, Auth 9099. If you have conflicts, stop other services or edit the PowerShell script to change ports.
- The test uses the project id `b-link-local` for emulator context. This does not touch production data.
- If you want to inspect emulator data manually, open the Emulator UI (if available) or use Firestore REST endpoints at `http://127.0.0.1:8080`.

Troubleshooting
- If puppeteer install fails due to Chromium download, you can set environment variable `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true` and use a system Chrome by passing `executablePath` in the script.

Security
- This flow uses local emulators only. Do not run it against production.
