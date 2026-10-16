// Agrégats anonymes de l'annuaire public, lus par l'app (écran « Mon jour »
// et constellation). Uniquement des comptes : aucun identifiant, et un nom
// n'apparaît que s'il est partagé par au moins MIN_NAME_COUNT profils.

const MIN_NAME_COUNT = 3;
const MAX_NAMES = 40;
const DAY_KEY = /^(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$/;

/** "élodie" / "Élodie " -> "elodie" : clé de regroupement. */
function nameKey(s) {
  return s
    .trim()
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '');
}

/** Première lettre en majuscule, pour l'affichage. */
function display(s) {
  const t = s.trim().toLowerCase();
  return t.replace(/(^|[\s-])(\p{L})/gu, (_, sep, c) => sep + c.toUpperCase());
}

/** Noms partagés par au moins `min` profils, du plus fréquent au moins. */
function topNames(map, min, max) {
  return [...map.values()]
    .filter((n) => n.count >= min)
    .sort((a, b) => b.count - a.count || a.name.localeCompare(b.name))
    .slice(0, max);
}

/**
 * profiles : données des documents `public_profiles`.
 * Renvoie { total, days: { 'MM-DD': n }, firstNames: [{name, count}],
 *           familyNames: [{name, count}] }.
 */
function aggregate(profiles, { minNameCount = MIN_NAME_COUNT, maxNames = MAX_NAMES } = {}) {
  const days = {};
  const first = new Map();
  const family = new Map();
  let total = 0;

  const add = (map, raw) => {
    const key = nameKey(raw);
    if (key.length < 2) return;
    const entry = map.get(key) || { name: display(raw), count: 0 };
    entry.count += 1;
    map.set(key, entry);
  };

  for (const p of profiles) {
    if (!p || p.isPublic === false) continue;
    const day = p.birthDayKey;
    if (typeof day !== 'string' || !DAY_KEY.test(day)) continue;
    total += 1;
    days[day] = (days[day] || 0) + 1;

    // Le nom n'est présent que si la personne a choisi de le montrer.
    if (p.publicName === true && typeof p.name === 'string') {
      const parts = p.name.trim().split(/\s+/).filter(Boolean);
      if (parts.length >= 1) add(first, parts[0]);
      if (parts.length >= 2) add(family, parts.slice(1).join(' '));
    }
  }

  return {
    total,
    days,
    firstNames: topNames(first, minNameCount, maxNames),
    familyNames: topNames(family, minNameCount, maxNames),
  };
}

module.exports = { aggregate, nameKey, MIN_NAME_COUNT };
