// Tests des règles Firestore (émulateur). Lancer : `npm test` dans test_rules/.
const { test, before, after, beforeEach } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const {
  doc, getDoc, setDoc, deleteDoc, collection, query, where, limit, getDocs,
} = require('firebase/firestore');

let env;

const google = (uid) =>
  env.authenticatedContext(uid, { firebase: { sign_in_provider: 'google.com' } })
    .firestore();
const anonymous = (uid) =>
  env.authenticatedContext(uid, { firebase: { sign_in_provider: 'anonymous' } })
    .firestore();

const publicProfile = (uid, extra = {}) => ({
  uid,
  name: 'Alice',
  birthDayKey: '10-14',
  isPublic: true,
  publicName: true,
  publicSocials: true,
  socialLinks: { instagram: 'https://instagram.com/alice' },
  ...extra,
});

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-b-link',
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8'),
    },
  });
});

after(() => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/alice'), {
      name: 'Alice', email: 'alice@example.com', isPublic: true,
      birthDate: '1990-10-14T00:00:00.000', birthDayKey: '10-14',
    });
    await setDoc(doc(db, 'public_profiles/alice'), publicProfile('alice'));
    await setDoc(doc(db, 'admins/boss'), { role: 'super_admin', isActive: true });
  });
});

// ---------- users : strictement privé ----------

test('un autre utilisateur ne peut PAS lire le profil privé, même public', async () => {
  await assertFails(getDoc(doc(google('bob'), 'users/alice')));
});

test('le propriétaire lit son profil privé', async () => {
  await assertSucceeds(getDoc(doc(google('alice'), 'users/alice')));
});

test('un admin lit les profils privés', async () => {
  await assertSucceeds(getDoc(doc(google('boss'), 'users/alice')));
});

test("on ne peut pas lister la collection users (fuite d'emails)", async () => {
  const q = query(collection(google('bob'), 'users'), where('isPublic', '==', true));
  await assertFails(getDocs(q));
});

test('personne ne lit les contacts d’un autre', async () => {
  await assertFails(getDoc(doc(google('bob'), 'users/alice/contacts/1')));
});

// ---------- public_profiles : annuaire ----------

test('un utilisateur Google voit les jumeaux d’anniversaire (requête paginée)', async () => {
  const q = query(collection(google('bob'), 'public_profiles'),
    where('birthDayKey', '==', '10-14'), limit(50));
  await assertSucceeds(getDocs(q));
});

test('une requête sans limite est refusée (anti-aspiration)', async () => {
  const q = query(collection(google('bob'), 'public_profiles'),
    where('birthDayKey', '==', '10-14'));
  await assertFails(getDocs(q));
});

test('une requête avec une limite > 50 est refusée', async () => {
  const q = query(collection(google('bob'), 'public_profiles'), limit(500));
  await assertFails(getDocs(q));
});

test('un compte anonyme ne peut pas parcourir l’annuaire', async () => {
  await assertFails(getDoc(doc(anonymous('anon'), 'public_profiles/alice')));
});

test('non connecté : aucun accès', async () => {
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'public_profiles/alice')));
});

test('le propriétaire publie sa projection publique', async () => {
  await assertSucceeds(setDoc(doc(google('bob'), 'public_profiles/bob'),
    publicProfile('bob', { birthDayKey: '02-29' })));
});

test('la projection publique refuse l’email (champ non autorisé)', async () => {
  await assertFails(setDoc(doc(google('bob'), 'public_profiles/bob'),
    publicProfile('bob', { email: 'bob@example.com' })));
});

test('on ne peut pas écrire la projection de quelqu’un d’autre', async () => {
  await assertFails(setDoc(doc(google('bob'), 'public_profiles/alice'),
    publicProfile('alice')));
});

test('uid incohérent refusé', async () => {
  await assertFails(setDoc(doc(google('bob'), 'public_profiles/bob'),
    publicProfile('alice')));
});

test('birthDayKey invalide refusé', async () => {
  await assertFails(setDoc(doc(google('bob'), 'public_profiles/bob'),
    publicProfile('bob', { birthDayKey: '13-45' })));
});

test('une projection marquée non publique est refusée (il faut la supprimer)', async () => {
  await assertFails(setDoc(doc(google('bob'), 'public_profiles/bob'),
    publicProfile('bob', { isPublic: false })));
});

test('le propriétaire peut retirer son profil de l’annuaire', async () => {
  await assertSucceeds(deleteDoc(doc(google('alice'), 'public_profiles/alice')));
});

test('un tiers ne peut pas supprimer le profil public d’un autre', async () => {
  await assertFails(deleteDoc(doc(google('bob'), 'public_profiles/alice')));
});

// ---------- admins / stats ----------

test('un utilisateur ne peut pas se promouvoir admin', async () => {
  await assertFails(setDoc(doc(google('bob'), 'admins/bob'), { role: 'super_admin' }));
});

test('le client ne peut pas écrire les statistiques', async () => {
  await assertFails(setDoc(doc(google('bob'), 'app_stats/global'), { totalUsers: 1e6 }));
});

// ---------- reports ----------

const { addDoc, serverTimestamp } = require('firebase/firestore');

const report = (reporter, extra = {}) => ({
  reporterUid: reporter, reportedUid: 'alice', reason: 'spam',
  createdAt: serverTimestamp(), ...extra,
});

test('un utilisateur peut signaler un profil', async () => {
  await assertSucceeds(addDoc(collection(google('bob'), 'reports'), report('bob')));
});

test('on ne peut pas signaler au nom de quelqu’un d’autre', async () => {
  await assertFails(addDoc(collection(google('bob'), 'reports'), report('carol')));
});

test('motif de signalement inconnu refusé', async () => {
  await assertFails(addDoc(collection(google('bob'), 'reports'),
    report('bob', { reason: 'je-veux-nuire' })));
});

test('un anonyme ne peut pas signaler', async () => {
  await assertFails(addDoc(collection(anonymous('anon'), 'reports'), report('anon')));
});

test('seuls les admins lisent les signalements', async () => {
  await assertFails(getDocs(query(collection(google('bob'), 'reports'), limit(10))));
  await assertSucceeds(getDocs(query(collection(google('boss'), 'reports'), limit(10))));
});
