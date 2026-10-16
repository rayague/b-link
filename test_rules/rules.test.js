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

// ---------- phase 6 : pays de résidence, semaine, mois ----------

const { orderBy } = require('firebase/firestore');

test('un code pays ISO est accepté dans la projection', async () => {
  await assertSucceeds(setDoc(doc(google('bob'), 'public_profiles/bob'),
    publicProfile('bob', { countryCode: 'CI', publicCountry: true })));
});

test('un code pays non ISO est refusé', async () => {
  await assertFails(setDoc(doc(google('bob'), 'public_profiles/bob'),
    publicProfile('bob', { countryCode: 'France', publicCountry: true })));
});

test('requête semaine (whereIn) paginée autorisée', async () => {
  const q = query(collection(google('bob'), 'public_profiles'),
    where('birthDayKey', 'in', ['10-12', '10-13', '10-14', '10-15', '10-16', '10-17', '10-18']),
    limit(50));
  await assertSucceeds(getDocs(q));
});

test('requête mois + pays paginée autorisée', async () => {
  const q = query(collection(google('bob'), 'public_profiles'),
    where('countryCode', '==', 'FR'),
    where('birthDayKey', '>=', '10-01'), where('birthDayKey', '<=', '10-31'),
    orderBy('birthDayKey'), limit(50));
  await assertSucceeds(getDocs(q));
});

test('requête mois sans limite refusée', async () => {
  const q = query(collection(google('bob'), 'public_profiles'),
    where('birthDayKey', '>=', '10-01'), where('birthDayKey', '<=', '10-31'),
    orderBy('birthDayKey'));
  await assertFails(getDocs(q));
});

// ---------- modération ----------

const hide = (uid) => env.withSecurityRulesDisabled((ctx) =>
  setDoc(doc(ctx.firestore(), `moderation/${uid}`), { hidden: true, reason: 'auto' }));

test('un profil masqué par la modération ne peut pas être republié', async () => {
  await hide('bob');
  await assertFails(setDoc(doc(google('bob'), 'public_profiles/bob'), publicProfile('bob')));
});

test('un profil masqué peut toujours retirer sa projection publique', async () => {
  await hide('alice');
  await assertSucceeds(deleteDoc(doc(google('alice'), 'public_profiles/alice')));
});

test('le propriétaire lit sa décision de modération, pas celle des autres', async () => {
  await hide('bob');
  await assertSucceeds(getDoc(doc(google('bob'), 'moderation/bob')));
  await assertFails(getDoc(doc(google('carol'), 'moderation/bob')));
});

test('un utilisateur ne peut pas lever son propre masquage', async () => {
  await hide('bob');
  await assertFails(deleteDoc(doc(google('bob'), 'moderation/bob')));
  await assertFails(setDoc(doc(google('bob'), 'moderation/bob'), { hidden: false }));
});

test('un admin masque et rétablit un profil, et traite les signalements', async () => {
  await assertSucceeds(setDoc(doc(google('boss'), 'moderation/alice'), { hidden: true }));
  await assertSucceeds(deleteDoc(doc(google('boss'), 'public_profiles/alice')));
  await assertSucceeds(deleteDoc(doc(google('boss'), 'moderation/alice')));
});

// ---------- blocages synchronisés ----------

test('un utilisateur gère sa liste de blocages', async () => {
  const ref = doc(google('bob'), 'users/bob/blocks/alice');
  await assertSucceeds(setDoc(ref, { name: 'Alice', blockedAt: serverTimestamp() }));
  await assertSucceeds(getDoc(ref));
  await assertSucceeds(deleteDoc(ref));
});

test('personne ne voit qui un autre utilisateur a bloqué', async () => {
  await env.withSecurityRulesDisabled((ctx) =>
    setDoc(doc(ctx.firestore(), 'users/bob/blocks/alice'), { name: 'Alice' }));
  await assertFails(getDoc(doc(google('alice'), 'users/bob/blocks/alice')));
  await assertFails(getDocs(query(collection(google('carol'), 'users/bob/blocks'), limit(10))));
});

test('on ne peut ni se bloquer soi-même ni ajouter des champs arbitraires', async () => {
  await assertFails(setDoc(doc(google('bob'), 'users/bob/blocks/bob'), { name: 'Moi' }));
  await assertFails(setDoc(doc(google('bob'), 'users/bob/blocks/alice'), { name: 'A', note: 'x' }));
});

// ---------- appareils (notifications push) ----------

test('un utilisateur enregistre et retire le jeton de son appareil', async () => {
  const ref = doc(google('bob'), 'users/bob/devices/token-123');
  await assertSucceeds(setDoc(ref, { platform: 'android', locale: 'fr', updatedAt: serverTimestamp() }));
  await assertSucceeds(deleteDoc(ref));
});

test('les jetons de notification des autres sont inaccessibles', async () => {
  await env.withSecurityRulesDisabled((ctx) =>
    setDoc(doc(ctx.firestore(), 'users/bob/devices/t'), { platform: 'ios', locale: 'en' }));
  await assertFails(getDoc(doc(google('alice'), 'users/bob/devices/t')));
  await assertFails(setDoc(doc(google('alice'), 'users/bob/devices/x'), { platform: 'ios', locale: 'en' }));
});

test('un jeton avec des champs ou une langue inattendus est refusé', async () => {
  await assertFails(setDoc(doc(google('bob'), 'users/bob/devices/t'), { platform: 'android', locale: 'de' }));
  await assertFails(setDoc(doc(google('bob'), 'users/bob/devices/t'), { platform: 'android', locale: 'fr', extra: 1 }));
});

// ---------- filtre "Ma ville" ----------

test('une clé de ville normalisée est acceptée, un format libre est refusé', async () => {
  await assertSucceeds(setDoc(doc(google('bob'), 'public_profiles/bob'),
    publicProfile('bob', { cityKey: 'FR:saint etienne' })));
  await assertFails(setDoc(doc(google('bob'), 'public_profiles/bob'),
    publicProfile('bob', { cityKey: 'Saint-Étienne' })));
});

test('requête par ville paginée autorisée', async () => {
  const q = query(collection(google('bob'), 'public_profiles'),
    where('cityKey', '==', 'CI:abidjan'), where('birthDayKey', '==', '10-15'), limit(50));
  await assertSucceeds(getDocs(q));
});

// ---------- rencontres entre jumeaux ----------

const { writeBatch, Timestamp, increment, updateDoc } = require('firebase/firestore');

const inOneWeek = () => Timestamp.fromMillis(Date.now() + 7 * 24 * 3600 * 1000);
const eventData = (creator, extra = {}) => ({
  creatorUid: creator, creatorName: null, title: 'Apéro des jumeaux',
  description: 'On fête ça ensemble !', placeHint: 'Café de la Gare',
  birthDayKey: '10-14', cityKey: 'FR:lyon', startsAt: inOneWeek(),
  maxAttendees: 2, attendeeCount: 0, cancelled: false,
  createdAt: serverTimestamp(), ...extra,
});

async function seedTwins() {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    // alice (déjà seedée) et bob : nés le 14/10 ; carol : un autre jour.
    await setDoc(doc(db, 'users/bob'), { birthDayKey: '10-14' });
    await setDoc(doc(db, 'users/carol'), { birthDayKey: '03-02' });
    await setDoc(doc(db, 'users/dave'), { birthDayKey: '10-14' }); // pas dans l'annuaire
    await setDoc(doc(db, 'users/erin'), { birthDayKey: '10-14' });
    for (const uid of ['bob', 'carol', 'erin']) {
      await setDoc(doc(db, `public_profiles/${uid}`), publicProfile(uid));
    }
    await setDoc(doc(db, 'events/e1'), { ...eventData('alice'), createdAt: Timestamp.now() });
  });
}

const join = (uid, eventId = 'e1', delta = 1) => {
  const db = google(uid);
  const b = writeBatch(db);
  b.set(doc(db, `events/${eventId}/attendees/${uid}`), { uid, name: null, joinedAt: serverTimestamp() });
  b.update(doc(db, `events/${eventId}`), { attendeeCount: increment(delta) });
  return b.commit();
};

test('un jumeau présent dans l\'annuaire organise une rencontre', async () => {
  await seedTwins();
  await assertSucceeds(setDoc(doc(google('bob'), 'events/new'), eventData('bob')));
});

test('rencontre invalide refusée (date passée, compteur, champ inconnu, autre jour)', async () => {
  await seedTwins();
  const past = Timestamp.fromMillis(Date.now() - 1000);
  await assertFails(setDoc(doc(google('bob'), 'events/x1'), eventData('bob', { startsAt: past })));
  await assertFails(setDoc(doc(google('bob'), 'events/x2'), eventData('bob', { attendeeCount: 5 })));
  await assertFails(setDoc(doc(google('bob'), 'events/x3'), eventData('bob', { phone: '06...' })));
  await assertFails(setDoc(doc(google('bob'), 'events/x4'), eventData('bob', { birthDayKey: '03-02' })));
  await assertFails(setDoc(doc(google('bob'), 'events/x5'), eventData('bob', { maxAttendees: 500 })));
});

test('hors annuaire public : ni organiser ni participer', async () => {
  await seedTwins();
  await assertFails(setDoc(doc(google('dave'), 'events/d1'), eventData('dave')));
  await assertFails(join('dave'));
});

test('seuls les jumeaux voient la rencontre, et en requête paginée', async () => {
  await seedTwins();
  await assertSucceeds(getDoc(doc(google('bob'), 'events/e1')));
  await assertFails(getDoc(doc(google('carol'), 'events/e1')));
  const ok = query(collection(google('bob'), 'events'),
    where('birthDayKey', '==', '10-14'), where('cityKey', '==', 'FR:lyon'), limit(50));
  await assertSucceeds(getDocs(ok));
  const otherDay = query(collection(google('bob'), 'events'),
    where('birthDayKey', '==', '03-02'), limit(50));
  await assertFails(getDocs(otherDay));
  const unbounded = query(collection(google('bob'), 'events'), where('birthDayKey', '==', '10-14'));
  await assertFails(getDocs(unbounded));
});

test('inscription et désinscription en lot, compteur cohérent', async () => {
  await seedTwins();
  await assertSucceeds(join('bob'));
  await assertFails(join('bob')); // déjà inscrit
  const db = google('bob');
  const b = writeBatch(db);
  b.delete(doc(db, 'events/e1/attendees/bob'));
  b.update(doc(db, 'events/e1'), { attendeeCount: increment(-1) });
  await assertSucceeds(b.commit());
});

test('impossible de tricher sur le compteur ou de dépasser la capacité', async () => {
  await seedTwins();
  await assertFails(join('bob', 'e1', 2)); // +2
  await assertFails(setDoc(doc(google('bob'), 'events/e1/attendees/bob'),
    { uid: 'bob', name: null, joinedAt: serverTimestamp() })); // sans compteur
  await assertFails(updateDoc(doc(google('bob'), 'events/e1'), { attendeeCount: 1 })); // sans participation
  await assertSucceeds(join('bob'));
  await assertSucceeds(join('erin')); // 2/2
  await env.withSecurityRulesDisabled((ctx) =>
    setDoc(doc(ctx.firestore(), 'public_profiles/alice'), publicProfile('alice')));
  await assertFails(join('alice')); // complet
});

test('l\'organisateur modifie ou annule, les autres non ; annulée = plus d\'inscription', async () => {
  await seedTwins();
  await assertFails(updateDoc(doc(google('bob'), 'events/e1'), { title: 'Piraté' }));
  await assertSucceeds(updateDoc(doc(google('alice'), 'events/e1'), { cancelled: true }));
  await assertFails(updateDoc(doc(google('alice'), 'events/e1'), { attendeeCount: 10 }));
  await assertFails(join('bob'));
});

test('suppression par l\'organisateur ou un admin seulement', async () => {
  await seedTwins();
  await assertFails(deleteDoc(doc(google('bob'), 'events/e1')));
  await assertSucceeds(deleteDoc(doc(google('alice'), 'events/e1')));
});
