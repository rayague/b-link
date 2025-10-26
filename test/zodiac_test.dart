import 'package:flutter_test/flutter_test.dart';
import 'package:b_link/utils/zodiac.dart';

void main() {
  test('zodiac: Aries (Bélier) boundary', () {
    final d = DateTime(1990, 3, 21);
    expect(Zodiac.computeZodiac(d), 'Bélier');
  });

  test('zodiac: Taurus (Taureau) boundary', () {
    final d = DateTime(1990, 4, 20);
    expect(Zodiac.computeZodiac(d), 'Taureau');
  });

  test('zodiac: Capricorn end of year', () {
    final d = DateTime(1990, 12, 31);
    expect(Zodiac.computeZodiac(d), 'Capricorne');
  });
}
