// API v1 (onCall(data, context), firestore.document().onCreate) : depuis
// firebase-functions v6, l'import racine expose l'API v2.
const functions = require('firebase-functions/v1');
// firebase-admin v14 n'expose plus que l'API modulaire.
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { shouldAutoHide, REPORT_THRESHOLD } = require('./moderation');

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
  await db.collection('moderation').doc(user.uid).delete();
  await db.collection('admins').doc(user.uid).delete();
  return null;
});


/**
 * Masque automatiquement un profil de l'annuaire quand assez de personnes
 * différentes l'ont signalé (voir moderation.js). La décision est écrite
 * dans moderation/{uid} : les règles Firestore empêchent alors toute
 * republication par le client. Un admin peut la confirmer ou la lever
 * depuis l'écran "Signalements".
 */
exports.onReportCreated = functions.firestore
  .document('reports/{reportId}')
  .onCreate(async (snap) => {
    const reportedUid = snap.get('reportedUid');
    if (typeof reportedUid !== 'string' || !reportedUid) return null;

    const reports = await db
      .collection('reports')
      .where('reportedUid', '==', reportedUid)
      .get();
    const reporters = reports.docs.map((d) => d.get('reporterUid'));

    const modRef = db.collection('moderation').doc(reportedUid);
    await db.runTransaction(async (tx) => {
      const existing = await tx.get(modRef);
      if (!shouldAutoHide(reporters, existing.exists ? existing.data() : null)) {
        return;
      }
      tx.set(modRef, {
        hidden: true,
        reason: 'auto_reports',
        reportCount: new Set(reporters.filter(Boolean)).size,
        threshold: REPORT_THRESHOLD,
        decidedAt: serverTimestamp(),
      });
      tx.delete(db.collection('public_profiles').doc(reportedUid));
    });
    return null;
  });
