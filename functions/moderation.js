/**
 * Règles de modération (pures, testables sans Firebase).
 */

/** Nombre de personnes DIFFÉRENTES qui doivent signaler un profil pour le masquer. */
const REPORT_THRESHOLD = 3;

/**
 * Le profil doit-il être masqué automatiquement ?
 *
 * @param {Array<string>} reporterUids auteurs de tous les signalements reçus
 * @param {object|null} existingDecision document moderation/{uid} existant
 * @returns {boolean}
 */
function shouldAutoHide(reporterUids, existingDecision) {
  // Une décision existe déjà : profil déjà masqué, ou rétabli par un admin
  // (hidden: false) ; dans ce cas, seul un admin peut changer d'avis.
  if (existingDecision) return false;
  return new Set(reporterUids.filter(Boolean)).size >= REPORT_THRESHOLD;
}

module.exports = { REPORT_THRESHOLD, shouldAutoHide };
