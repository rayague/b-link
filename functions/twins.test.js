const { test } = require('node:test');
const assert = require('node:assert');
const { shouldNotifyTwin, twinMessage, TWIN_NOTIFY_INTERVAL_MS } = require('./twins');

const now = Date.UTC(2026, 9, 16, 12);

test('on ne se prévient pas soi-même', () => {
  assert.strictEqual(shouldNotifyTwin({ uid: 'a' }, 'a', now), false);
});

test('activé par défaut, désactivable', () => {
  assert.strictEqual(shouldNotifyTwin({ uid: 'b' }, 'a', now), true);
  assert.strictEqual(shouldNotifyTwin({ uid: 'b', notifyNewTwins: false }, 'a', now), false);
});

test('au plus une notification par 24 h', () => {
  const recent = { toMillis: () => now - 2 * 60 * 60 * 1000 };
  const old = { toMillis: () => now - TWIN_NOTIFY_INTERVAL_MS - 1 };
  assert.strictEqual(shouldNotifyTwin({ uid: 'b', lastTwinNotifiedAt: recent }, 'a', now), false);
  assert.strictEqual(shouldNotifyTwin({ uid: 'b', lastTwinNotifiedAt: old }, 'a', now), true);
});

test('le nom n\'apparaît que s\'il est public, dans la langue du destinataire', () => {
  assert.match(twinMessage('fr', 'Awa').body, /^Awa fête son anniversaire/);
  assert.match(twinMessage('fr', null).body, /^Quelqu'un fête/);
  assert.match(twinMessage('en', '  ').body, /^Someone celebrates/);
  assert.match(twinMessage('de', 'Tom').title, /birthday twin/); // repli anglais
});

test('formulation neutre (pas de "né(e)")', () => {
  for (const lang of ['fr', 'en']) {
    for (const name of ['Awa', null]) {
      assert.doesNotMatch(twinMessage(lang, name).body, /née?\b|\(e\)/);
    }
  }
});

test('wish notification uses the public name or stays anonymous', () => {
  const { wishMessage } = require('./twins');
  assert.match(wishMessage('fr', 'Léa').body, /^Léa vous souhaite/);
  assert.doesNotMatch(wishMessage('fr', null).body, /null/);
  assert.match(wishMessage('en', '  ').body, /^Someone/);
});
