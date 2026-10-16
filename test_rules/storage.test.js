// Règles Firebase Storage (photos de profil), avec lecture croisée de
// Firestore (public_profiles/{uid}.publicPhoto). Lancer : npm test.
const { test, before, after, beforeEach } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { doc, setDoc, deleteDoc } = require('firebase/firestore');
const { ref, uploadBytes, getBytes, deleteObject } = require('firebase/storage');

let env;
const jpeg = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 1, 2, 3]);
const meta = { contentType: 'image/jpeg' };
const photo = (uid) => `profile_photos/${uid}/photo.jpg`;

const google = (uid) =>
  env.authenticatedContext(uid, { firebase: { sign_in_provider: 'google.com' } });
const anonymous = (uid) =>
  env.authenticatedContext(uid, { firebase: { sign_in_provider: 'anonymous' } });

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-b-link',
    firestore: { rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8') },
    storage: { rules: fs.readFileSync(path.join(__dirname, '..', 'storage.rules'), 'utf8') },
  });
});

after(() => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.clearStorage();
  await env.withSecurityRulesDisabled(async (ctx) => {
    await uploadBytes(ref(ctx.storage(), photo('alice')), jpeg, meta);
  });
});

const setPublic = (uid, publicPhoto) =>
  env.withSecurityRulesDisabled((ctx) =>
    setDoc(doc(ctx.firestore(), `public_profiles/${uid}`), {
      uid, birthDayKey: '10-15', isPublic: true, publicPhoto,
    }));

test('le propriétaire envoie et relit sa photo', async () => {
  const s = google('bob').storage();
  await assertSucceeds(uploadBytes(ref(s, photo('bob')), jpeg, meta));
  await assertSucceeds(getBytes(ref(s, photo('bob'))));
});

test('photo partagée : visible des autres membres', async () => {
  await setPublic('alice', true);
  await assertSucceeds(getBytes(ref(google('bob').storage(), photo('alice'))));
});

test('photo non partagée : invisible pour les autres', async () => {
  await setPublic('alice', false);
  await assertFails(getBytes(ref(google('bob').storage(), photo('alice'))));
});

test('profil privé ou masqué (pas de fiche publique) : photo invisible', async () => {
  await assertFails(getBytes(ref(google('bob').storage(), photo('alice'))));
});

test('retirer la fiche publique coupe immédiatement l\'accès', async () => {
  await setPublic('alice', true);
  await env.withSecurityRulesDisabled((ctx) =>
    deleteDoc(doc(ctx.firestore(), 'public_profiles/alice')));
  await assertFails(getBytes(ref(google('bob').storage(), photo('alice'))));
});

test('comptes anonymes et non connectés : aucun accès', async () => {
  await setPublic('alice', true);
  await assertFails(getBytes(ref(anonymous('anon').storage(), photo('alice'))));
  await assertFails(getBytes(ref(env.unauthenticatedContext().storage(), photo('alice'))));
});

test('on ne peut ni écrire ni supprimer la photo de quelqu\'un d\'autre', async () => {
  const s = google('bob').storage();
  await assertFails(uploadBytes(ref(s, photo('alice')), jpeg, meta));
  await assertFails(deleteObject(ref(s, photo('alice'))));
});

test('fichiers trop gros ou non-images refusés', async () => {
  const s = google('bob').storage();
  await assertFails(uploadBytes(ref(s, photo('bob')), new Uint8Array(1024 * 1024 + 1), meta));
  await assertFails(uploadBytes(ref(s, photo('bob')), jpeg, { contentType: 'application/pdf' }));
});

test('aucun autre chemin n\'est accessible', async () => {
  await assertFails(uploadBytes(ref(google('bob').storage(), 'autre/fichier.jpg'), jpeg, meta));
});

test('le propriétaire supprime sa photo', async () => {
  const s = google('alice').storage();
  await assertSucceeds(deleteObject(ref(s, photo('alice'))));
});
