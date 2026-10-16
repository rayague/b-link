 # Final acceptance checklist — b_link

 Follow these steps to verify production readiness and finalize delivery.

 ## 1) Pre-deployment (local validation)

 - Run `flutter analyze` and fix any critical issues.
 - Run `flutter test` and ensure unit tests pass.
 - Run emulator E2E (client-only) to validate basic write/read:

   ```cmd
   firebase emulators:exec "node tool/client_smoke_emulator_puppet.js" --only auth,firestore --project b-link-local --debug
   ```

 - Optionally test functions locally:

   ```cmd
   set GCLOUD_PROJECT=b-link-local
   firebase emulators:exec "node tool/client_smoke_emulator_puppet.js" --only auth,firestore,functions --project b-link-local --debug
   ```

 ## 2) Enable Blaze and deploy to production

 - Enable Blaze (Firebase Console).
 - Run `scripts/deploy_prod.sh <PROJECT_ID>` (Linux/macOS) or `scripts\deploy_prod.cmd <PROJECT_ID>` (Windows).

 ## 3) Post-deploy validation

 - Run production smoke script (update `tool/client_smoke_emulator_puppet.js` or use production web client script) to create a profile and verify the document is normalized.
 - Verify Cloud Function logs in Firebase Console (Functions → Logs) to confirm normalizer executed.
 - Test that strict create rules now apply and that normal clients still succeed.

 ## 4) Build & sign release

 - Add keystore to CI secrets or sign locally.
 - Build AAB:

   ```cmd
   flutter build appbundle --release
   ```

 - Sign/upload to Play Console, or upload unsigned AAB and use Play App Signing.

 ## 5) Final acceptance on device

 - Install release build on a test device.
 - Create profile while offline, then reconnect and confirm sync processed and Firestore document normalized.
 - Admin verifies document fields and that no forbidden fields exist.

 ## 6) Rollback plan

 - If rules break, restore `firestore.rules.bak` and redeploy rules:

   ```cmd
   copy firestore.rules.bak firestore.rules
   firebase deploy --only firestore:rules --project <PROJECT_ID>
   ```

 If you want, I can run steps 2 and 3 after you enable Blaze and give me the production project id, or you can run `scripts/deploy_prod.*` locally and paste logs here for analysis.
