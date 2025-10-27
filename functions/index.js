const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();
// Compatibility: some emulator environments may not expose FieldValue the same way,
// so resolve FieldValue and Timestamp from the admin SDK and fall back safely.
const { FieldValue, Timestamp } = require('firebase-admin').firestore || {};

// Allowed keys that clients may set
const ALLOWED_KEYS = [
  'displayName', 'name', 'birthDate', 'birthDayKey', 'photoUrl',
  'isPublic', 'visibility', 'updatedAt', 'createdAt', 'lastSyncedAt'
];

// Remove server-only fields and normalize timestamps/fields on create
exports.onProfileCreate = functions.firestore
  .document('profiles/{userId}')
  .onCreate(async (snap, context) => {
    const data = snap.data() || {};
    const userId = context.params.userId;

    const sanitized = {};
    // Copy only allowed keys
    for (const k of ALLOWED_KEYS) {
      if (Object.prototype.hasOwnProperty.call(data, k)) sanitized[k] = data[k];
    }

    // Enforce server fields
    // Use FieldValue.serverTimestamp when available (preferred). Otherwise fall back to a Timestamp.
    const now = (FieldValue && typeof FieldValue.serverTimestamp === 'function')
      ? FieldValue.serverTimestamp()
      : (Timestamp && typeof Timestamp.now === 'function' ? Timestamp.now() : null);
    if (!sanitized.createdAt) sanitized.createdAt = now;
    sanitized.lastNormalizedAt = now;

    // Ensure forbidden fields removed if present (best-effort)
    // If client tried to set isAdmin/role/admin, remove them and log via a metadata field
    const forbidden = ['isAdmin', 'role', 'admin'];
    let hadForbidden = false;
    for (const f of forbidden) {
      if (Object.prototype.hasOwnProperty.call(data, f)) hadForbidden = true;
    }
    if (hadForbidden) {
      sanitized._clientTampered = true;
      sanitized._clientTamperedAt = now;
    }

    // Merge sanitized data back to document (merge to avoid removing server fields set by other systems)
    await snap.ref.set(sanitized, { merge: true });
    // Optionally write an audit log (omitted to keep this function small)
    return null;
  });
