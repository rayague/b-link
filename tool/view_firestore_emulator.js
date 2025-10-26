#!/usr/bin/env node
// Read documents from Firestore emulator's `profiles` collection.
// Usage: node tool/view_firestore_emulator.js [--host host:port] [--project projectId] [--limit N]

const admin = require('firebase-admin');

function parseArgs() {
  const out = { host: process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080', project: 'b-link-local', limit: 100 };
  const args = process.argv.slice(2);
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if (a === '--host' && args[i+1]) out.host = args[++i];
    else if (a === '--project' && args[i+1]) out.project = args[++i];
    else if (a === '--limit' && args[i+1]) out.limit = parseInt(args[++i], 10) || out.limit;
    else if (a === '--help' || a === '-h') out.help = true;
  }
  return out;
}

const opts = parseArgs();
if (opts.help) {
  console.log('Usage: node tool/view_firestore_emulator.js [--host host:port] [--project projectId] [--limit N]');
  process.exit(0);
}

// Ensure the admin SDK connects to emulator
process.env.FIRESTORE_EMULATOR_HOST = opts.host;

// Initialize admin with explicit projectId (no credentials needed for emulator)
try {
  admin.initializeApp({ projectId: opts.project });
} catch (e) {
  // ignore if already initialized
}

const db = admin.firestore();

(async function main() {
  try {
    console.log('Connecting to Firestore emulator at', process.env.FIRESTORE_EMULATOR_HOST, 'project:', opts.project);
    const snap = await db.collection('profiles').limit(opts.limit).get();
    console.log('Found', snap.size, 'documents');
    snap.forEach(doc => {
      console.log('---');
      console.log('id:', doc.id);
      console.log(JSON.stringify(doc.data(), null, 2));
    });
    process.exit(0);
  } catch (err) {
    console.error('Error reading from emulator:', err && err.stack ? err.stack : err);
    process.exit(1);
  }
})();
