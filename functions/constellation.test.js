const test = require('node:test');
const assert = require('node:assert');
const { aggregate, nameKey } = require('./constellation');

const p = (name, day, extra = {}) => ({
  name,
  birthDayKey: day,
  publicName: name !== null,
  isPublic: true,
  ...extra,
});

test('counts births per day and ignores invalid keys', () => {
  const r = aggregate([
    p('Ray Ague', '03-21'),
    p(null, '03-21'),
    p('Léa Martin', '12-25'),
    p('X', '13-40'),
    p('Y', undefined),
  ]);
  assert.strictEqual(r.total, 3);
  assert.deepStrictEqual(r.days, { '03-21': 2, '12-25': 1 });
});

test('names below the threshold are never published', () => {
  const r = aggregate([
    p('Léa Martin', '01-01'),
    p('lea Dupont', '01-02'),
    p('LÉA Martin', '01-03'),
    p('Noah Martin', '01-04'),
    p('Ray Ague', '01-05'),
  ]);
  assert.deepStrictEqual(r.firstNames, [{ name: 'Léa', count: 3 }]);
  assert.deepStrictEqual(r.familyNames, [{ name: 'Martin', count: 3 }]);
});

test('hidden names and private profiles are not counted', () => {
  const r = aggregate(
    [
      p('Léa A', '01-01', { publicName: false }),
      p('Léa B', '01-01', { isPublic: false }),
      p('Léa C', '01-01'),
    ],
    { minNameCount: 1 }
  );
  assert.strictEqual(r.total, 2);
  assert.deepStrictEqual(r.firstNames, [{ name: 'Léa', count: 1 }]);
});

test('name keys ignore case and accents', () => {
  assert.strictEqual(nameKey(' Élodie '), nameKey('elodie'));
});
