#!/usr/bin/env node
// Simple admin script to list documents from the `profiles` collection using
// the Firebase Admin SDK. This script must be run with a Google service
// account JSON key. Do NOT commit that key to source control.

const admin = require('firebase-admin');
const fs = require('fs');

function parseArgs() {
  const out = { key: process.env.GOOGLE_APPLICATION_CREDENTIALS, limit: 100, writeSmoke: false, smokeId: null };
  const args = process.argv.slice(2);
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if (a === '--key' && args[i+1]) { out.key = args[++i]; }
    else if (a === '--limit' && args[i+1]) { out.limit = parseInt(args[++i], 10) || out.limit; }
    else if (a === '--writeSmoke') { out.writeSmoke = true; }
    else if (a === '--smokeId' && args[i+1]) { out.smokeId = args[++i]; }
    else if (a === '--help' || a === '-h') { out.help = true; }
  }
  return out;
}

const opts = parseArgs();
if (opts.help) {
  console.log('Usage: node tool/view_firestore_admin.js [--key path/to/serviceAccount.json] [--limit N]');
  process.exit(0);
}

if (opts.key && !process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  process.env.GOOGLE_APPLICATION_CREDENTIALS = opts.key;
}

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('ERROR: No service account key provided. Set GOOGLE_APPLICATION_CREDENTIALS or pass --key');
  process.exit(2);
}

if (!fs.existsSync(process.env.GOOGLE_APPLICATION_CREDENTIALS)) {
  console.error('ERROR: service account key file not found at', process.env.GOOGLE_APPLICATION_CREDENTIALS);
  process.exit(3);
}

try {
  admin.initializeApp({ credential: admin.credential.applicationDefault() });
} catch (e) {
  // ignore if already initialized
}

const db = admin.firestore();

(async function main() {
  try {
    console.log('Using credentials:', process.env.GOOGLE_APPLICATION_CREDENTIALS);
    console.log('Reading up to', opts.limit, 'documents from collection: profiles');
    const snap = await db.collection('profiles').limit(opts.limit).get();
    console.log('Found', snap.size, 'documents');
    snap.forEach(doc => {
      console.log('---');
      console.log('id:', doc.id);
      console.log(JSON.stringify(doc.data(), null, 2));
    });

    // Optionally write a smoke document to validate writes (admin path)
    if (opts.writeSmoke) {
      const id = opts.smokeId || `smoke-${Date.now()}`;
      console.log('Writing smoke document with id:', id);
      const now = new Date().toISOString();
      const data = {
        name: 'Smoke Test Name',
        birthDate: '1990-01-01',
        displayName: 'Smoke Test',
        lastSyncedAt: now
      };
      try {
        await db.collection('profiles').doc(id).set(data);
        console.log('Smoke document written:', id);
      } catch (e) {
        console.error('Failed to write smoke document:', e && e.stack ? e.stack : e);
        process.exit(4);
      }
    }
    process.exit(0);
  } catch (err) {
    console.error('Failed to read profiles:', err && err.stack ? err.stack : err);
    process.exit(1);
  }
})();
