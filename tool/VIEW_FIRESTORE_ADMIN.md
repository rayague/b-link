# View Firestore (Admin) — tool/view_firestore_admin.js

This helper uses the Firebase Admin SDK to list documents from the `profiles` collection. It requires a Google service account JSON key with access to the project (Firestore Viewer or Owner role).

Security notice
- Do NOT commit your service account key to the repository.
- Prefer setting the environment variable `GOOGLE_APPLICATION_CREDENTIALS` to point to the JSON file.

Setup

1. Install Node dependencies (in the project root):

```powershell
cd D:\Projects\b_link
npm install --prefix .\tool
```

2. Create a service account in your Google Cloud project and download the JSON key.
   - Console: IAM & Admin > Service Accounts > Create Service Account
   - Grant `Firestore Viewer` (or broader) role, then create and download key JSON.

3. Run the script (examples):

Use env var:
```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = 'C:\path\to\serviceAccountKey.json'
node tool/view_firestore_admin.js --limit 200
```

Or pass key directly:
```powershell
node tool/view_firestore_admin.js --key C:\path\to\serviceAccountKey.json --limit 50
```

What it does
- Connects to Firestore using Admin SDK (service account). This bypasses client security rules (server-side access).
- Lists up to `--limit` documents in `profiles` and prints their IDs and JSON payloads.

When to use
- To inspect production data when client rules (or deny-all) block access.
- For ad-hoc administration and verification.

Afterwards
- Remove or secure the JSON key. If you accidentally committed it, rotate the key immediately in the Cloud Console.

Emulator usage
----------------
If you want to inspect a local Firestore emulator (no service account required), use the emulator viewer script:

1. Start the emulator:

```powershell
cd D:\Projects\b_link
firebase emulators:start --only firestore,auth --project b-link-local --config .\firebase.json
```

2. In another shell run:

```powershell
npm run view-emulator --prefix .\tool
```

Or pass host/project/limit explicitly:

```powershell
node tool\view_firestore_emulator.js --host 127.0.0.1:8080 --project b-link-local --limit 200
```

This script uses the Firebase Admin SDK configured to point to the emulator and will list documents under `profiles`.
