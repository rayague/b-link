/**
 * Notification "nouveau jumeau d'anniversaire" : règles pures, testables
 * sans Firebase.
 */

/** Au plus une notification de ce type par jour et par personne. */
const TWIN_NOTIFY_INTERVAL_MS = 24 * 60 * 60 * 1000;

const toMillis = (v) => {
  if (!v) return null;
  if (typeof v.toMillis === 'function') return v.toMillis(); // Timestamp
  if (v instanceof Date) return v.getTime();
  return typeof v === 'number' ? v : null;
};

/**
 * Faut-il prévenir ce destinataire de l'arrivée de newUid ?
 * @param {{uid: string, notifyNewTwins?: boolean, lastTwinNotifiedAt?: any}} recipient
 */
function shouldNotifyTwin(recipient, newUid, now) {
  if (!recipient || !recipient.uid || recipient.uid === newUid) return false;
  // Activé par défaut ; l'utilisateur peut le couper dans les réglages.
  if (recipient.notifyNewTwins === false) return false;
  const last = toMillis(recipient.lastTwinNotifiedAt);
  return last === null || now - last >= TWIN_NOTIFY_INTERVAL_MS;
}

/**
 * Texte de la notification. Le nom n'est utilisé que s'il est public.
 * Formulations neutres (pas de "né / née").
 */
function twinMessage(lang, publicName) {
  const name = typeof publicName === 'string' && publicName.trim() ? publicName.trim() : null;
  if (lang === 'fr') {
    return {
      title: "🎂 Un nouveau jumeau d'anniversaire !",
      body: name
        ? `${name} fête son anniversaire le même jour que vous. Venez lui dire bonjour 👋`
        : "Quelqu'un fête son anniversaire le même jour que vous. Venez découvrir qui 👋",
    };
  }
  return {
    title: '🎂 A new birthday twin!',
    body: name
      ? `${name} celebrates their birthday on the same day as you. Come and say hi 👋`
      : 'Someone celebrates their birthday on the same day as you. Come and see who 👋',
  };
}

/**
 * Notification « vœu d'anniversaire reçu ». Le nom n'est présent que s'il
 * est public (les règles Firestore l'imposent).
 */
function wishMessage(lang, fromName) {
  const name = typeof fromName === 'string' && fromName.trim() ? fromName.trim() : null;
  if (lang === 'fr') {
    return {
      title: "Un vœu d'anniversaire pour vous",
      body: name
        ? `${name} vous souhaite un joyeux anniversaire.`
        : "Une personne née le même jour que vous vous souhaite un joyeux anniversaire.",
    };
  }
  return {
    title: 'A birthday wish for you',
    body: name
      ? `${name} wishes you a happy birthday.`
      : 'Someone born on the same day as you wishes you a happy birthday.',
  };
}

/**
 * Messages déjà reçus par le destinataire cette année, après l'ajout de
 * [wish] (remis à zéro au changement d'année).
 */
function usedWishes(previous, wish, year) {
  const prev = previous && previous.year === year && Array.isArray(previous.used)
    ? previous.used.filter((n) => Number.isInteger(n))
    : [];
  return { year, used: [...new Set([...prev, wish])].sort((a, b) => a - b) };
}

/** Codes d'erreur FCM signifiant que le jeton n'est plus valide. */
const INVALID_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
  'messaging/invalid-argument',
]);

module.exports = {
  TWIN_NOTIFY_INTERVAL_MS,
  shouldNotifyTwin,
  twinMessage,
  wishMessage,
  usedWishes,
  INVALID_TOKEN_CODES,
};
