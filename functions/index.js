const functions = require('firebase-functions');
const admin = require('firebase-admin');
// FieldValue via the modular subpath export: the admin namespace's
// `firestore.FieldValue` static is not always exposed (e.g. under the
// Functions emulator), whereas this export is always available.
const { FieldValue } = require('firebase-admin/firestore');

admin.initializeApp();
const db = admin.firestore();

const serverTimestamp = () =>
  (FieldValue && typeof FieldValue.serverTimestamp === 'function')
    ? FieldValue.serverTimestamp()
    : new Date().toISOString();

/**
 * Grant (or update) an admin role for a given Firebase Auth uid.
 *
 * Security:
 * - Only an existing, active `super_admin` can call this function.
 * - The document id is always the target uid (`admins/{uid}`).
 *
 * Bootstrap of the FIRST super_admin must be done out-of-band (Firebase
 * console or admin SDK script), because no admin exists yet to authorize
 * the call. Never seed credentials from the client app.
 */
exports.grantAdmin = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Authentication required.'
    );
  }

  const callerDoc = await db.collection('admins').doc(context.auth.uid).get();
  const caller = callerDoc.exists ? callerDoc.data() : null;
  if (!caller || caller.role !== 'super_admin' || caller.isActive === false) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only an active super_admin can grant admin access.'
    );
  }

  const uid = typeof data.uid === 'string' ? data.uid.trim() : '';
  if (!uid) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'A target `uid` is required.'
    );
  }

  const role = data.role === 'super_admin' ? 'super_admin' : 'admin';
  let email = typeof data.email === 'string' ? data.email : '';
  if (!email) {
    try {
      const userRecord = await admin.auth().getUser(uid);
      email = userRecord.email || '';
    } catch (_) {
      email = '';
    }
  }

  await db.collection('admins').doc(uid).set(
    {
      uid,
      email,
      role,
      isActive: true,
      createdAt: serverTimestamp(),
      lastLogin: null,
    },
    { merge: true }
  );

  return { success: true, uid, role };
});

/**
 * Maintain the global user counter server-side.
 * Replaces the previous client-side write to `app_stats/global`.
 */
exports.onUserCreated = functions.firestore
  .document('users/{userId}')
  .onCreate(async () => {
    const statsRef = db.collection('app_stats').doc('global');
    await statsRef.set(
      {
        totalUsers: FieldValue.increment(1),
        lastUpdated: serverTimestamp(),
      },
      { merge: true }
    );
    return null;
  });
