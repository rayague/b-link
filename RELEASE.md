Release checklist for b_link

This document lists the minimal steps to produce a production release (Firestore rules + Cloud Functions + Android/iOS builds).

Prerequisites
- Firebase project created for production.
- Owner/Editor access to the Firebase project to enable billing (Blaze) and deploy functions.
- Firebase CLI installed and authenticated: `npm install -g firebase-tools` and `firebase login`
- Flutter SDK installed locally and on PATH. Run `flutter doctor -v` and fix any issues (Visual Studio toolchain on Windows, Xcode on macOS for iOS builds).

1) Enable Blaze for the Firebase project
- Console: https://console.firebase.google.com
- Select the production project -> Billing / Upgrade to Blaze -> pick billing account

2) Deploy Cloud Functions (normalizer)
- Ensure you have the correct project id (e.g., `my-prod-project`)
- From repository root:

```cmd
set GCLOUD_PROJECT=my-prod-project
firebase deploy --only functions --project my-prod-project
```

Note: Functions may require Node 18 as specified in `functions/package.json`.

3) Deploy Firestore rules (tighten create validation)
- After functions are deployed and tested, update `firestore.rules` to the strict production variant (we keep `firestore.rules.prod` in the repo).
- Deploy:

```cmd
firebase deploy --only firestore:rules --project my-prod-project
```

Rollback: to revert to previous rules, use `firestore.rules.bak` and deploy it:

```cmd
copy firestore.rules.bak firestore.rules
firebase deploy --only firestore:rules --project my-prod-project
```

4) Run production smoke test (optional but recommended)
- Use the headless Puppeteer smoke script (adjust the script config to point to your production project/web config).

5) Build Android release (example)
- Create or use an existing keystore and add signing config to `android/app/build.gradle` or CI secrets.
- Build AAB:

```cmd
flutter build appbundle --release
```

- To locally sign when needed, follow standard Android keystore steps.

6) Build iOS release
- On macOS with Xcode installed, set up signing and run:

```bash
flutter build ipa --release
```

7) CI
- The repository contains a GitHub Actions workflow `.github/workflows/ci.yml` that runs analyze, unit tests, and the emulator smoke test. Verify secrets are set and the workflow is active.

8) Build AAB via CI

 - A GitHub Actions workflow `.github/workflows/release.yml` is included to build an unsigned Android App Bundle (AAB) and upload it as a workflow artifact.
 - If you want the AAB signed in CI, add these repository secrets:
	 - `ANDROID_KEYSTORE_BASE64` — base64-encoded keystore file
	 - `ANDROID_KEYSTORE_PASSWORD`
	 - `ANDROID_KEY_ALIAS`
	 - `ANDROID_KEY_PASSWORD`

 - To trigger the release build manually, go to Actions → Release Build (Android AAB) → Run workflow, or push a tag like `v1.0.0`.

Notes about signing:
 - The workflow demonstrates a simple jarsigner step for demonstration; for Play Store uploads you can also upload an unsigned AAB and let Google Play App Signing manage the key (recommended if you don't want to store signing keys in CI).
 - If you prefer me to wire full Play Console deployment steps, provide the necessary service account and I can extend the workflow.

Notes & caveats
- Cloud Functions deployment requires Blaze (artifact registry & cloudbuild). Enabling Blaze may incur costs.
- If you cannot enable Blaze, you can validate and run functions locally with the Firebase emulator before deploying rules; however, the production rules should only be hardened after normalizer is deployed.

If you want, I can:
- Deploy the functions and rules once you confirm Blaze is enabled and provide the production project id.
- Prepare signed builds if you provide keystore / signing credentials.
- Finalize background sync native wiring (WorkManager/BGTask) before release (extra work).
