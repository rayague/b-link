E2E helper for Firebase emulator

This repository includes a small PowerShell helper that starts the Firebase emulators (Firestore + Auth), creates an anonymous user, writes a test profile document, verifies it, and stops the emulators.

Usage (Windows PowerShell):

```powershell
cd D:\Projects\b_link
# Run the E2E helper (may require firebase CLI installed and accessible in PATH)
.\tool\run_emulator_e2e.ps1
```

Notes:
- The helper requires the Firebase CLI (`firebase`) installed and logged in for emulator management. It uses the `b-link-local` project alias defined in `.firebaserc`.
- The script will start the emulators with the config in `firebase.json` and stop them when finished.
- The script uses the Auth emulator to create an anonymous user and then writes a Firestore document under `/profiles/{uid}` using the returned idToken. This validates anonymous auth and Firestore writes locally.
- Be careful: emulator logs will appear in the terminal started by the script. If the emulators do not start, check that no other process is using ports 8080/9099.

Security:
- The script expects the `firestore.rules` file to enforce owner-only access. For local debugging you may temporarily relax rules, but always restore them.
