import 'package:b_link/l10n/zodiac_portraits.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every sign has a full portrait in both languages', () {
    for (final id in kZodiacOrder) {
      for (final lang in ['fr', 'en']) {
        final p = ZodiacPortrait.of(id, lang);
        expect(p, isNotNull, reason: '$id $lang');
        expect(p!.portrait, hasLength(3), reason: '$id $lang');
        expect(p.gifts, hasLength(4), reason: '$id $lang');
        expect(p.growth, hasLength(2), reason: '$id $lang');
        for (final text in [p.love, p.friendship, p.work, ...p.portrait]) {
          expect(text.length, greaterThan(60), reason: '$id $lang');
        }
      }
    }
  });

  test('affinities, opposite sign and modality follow the tradition', () {
    expect(zodiacAffinities('Bélier'),
        ['Lion', 'Sagittaire', 'Gémeaux', 'Balance', 'Verseau']);
    expect(zodiacAffinities('Cancer'),
        ['Scorpion', 'Poissons', 'Taureau', 'Vierge', 'Capricorne']);
    expect(zodiacOpposite('Bélier'), 'Balance');
    expect(zodiacOpposite('Sagittaire'), 'Gémeaux');
    expect(zodiacModality('Bélier'), 0); // cardinal
    expect(zodiacModality('Verseau'), 1); // fixe
    expect(zodiacModality('Sagittaire'), 2); // mutable
  });
}
