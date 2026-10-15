// API v1 (onCall(data, context), firestore.document().onCreate) : depuis
// firebase-functions v6, l'import racine expose l'API v2.
const functions = require('firebase-functions/v1');
// firebase-admin v14 n'expose plus que l'API modulaire.
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

initializeApp();
const db = getFirestore();

const serverTimestamp = () => FieldValue.serverTimestamp();

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
      const userRecord = await getAuth().getUser(uid);
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

/**
 * Keep the global user counter accurate when a profile is removed.
 */
exports.onUserDeleted = functions.firestore
  .document('users/{userId}')
  .onDelete(async () => {
    await db.collection('app_stats').doc('global').set(
      {
        totalUsers: FieldValue.increment(-1),
        lastUpdated: serverTimestamp(),
      },
      { merge: true }
    );
    return null;
  });

/**
 * Safety net for account deletion: when a Firebase Auth account is deleted
 * (from the app, the console or the Admin SDK), remove all of its data,
 * including sub-collections the client may not have cleaned up.
 */
exports.onAuthUserDeleted = functions.auth.user().onDelete(async (user) => {
  await db.recursiveDelete(db.collection('users').doc(user.uid));
  await db.collection('public_profiles').doc(user.uid).delete();
  await db.collection('admins').doc(user.uid).delete();
  return null;
});
