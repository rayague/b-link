// node --test (dans functions/)
const { test } = require('node:test');
const assert = require('node:assert');
const { shouldAutoHide, REPORT_THRESHOLD } = require('./moderation');

test('le seuil est de 3 personnes différentes', () => {
  assert.strictEqual(REPORT_THRESHOLD, 3);
  assert.strictEqual(shouldAutoHide(['a', 'b'], null), false);
  assert.strictEqual(shouldAutoHide(['a', 'b', 'c'], null), true);
});

test('une même personne qui signale plusieurs fois ne compte qu\'une fois', () => {
  assert.strictEqual(shouldAutoHide(['a', 'a', 'a', 'b'], null), false);
});

test('pas de nouvelle décision si un admin a déjà tranché', () => {
  assert.strictEqual(shouldAutoHide(['a', 'b', 'c', 'd'], { hidden: false }), false);
  assert.strictEqual(shouldAutoHide(['a', 'b', 'c'], { hidden: true }), false);
});

test('les signalements sans auteur sont ignorés', () => {
  assert.strictEqual(shouldAutoHide(['a', 'b', undefined, null], null), false);
});
