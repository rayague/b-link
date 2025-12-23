import 'package:flutter_test/flutter_test.dart';
import 'package:b_link/utils/zodiac.dart';

void main() {
  group('Zodiac Utils Tests', () {
    test('getZodiacSign retourne le bon signe pour Bélier', () {
      final sign = getZodiacSign(DateTime(1990, 3, 21));
      expect(sign, 'ARIES');
    });

    test('getZodiacSign retourne le bon signe pour Taureau', () {
      final sign = getZodiacSign(DateTime(1990, 5, 10));
      expect(sign, 'TAURUS');
    });

    test('getZodiacSign retourne le bon signe pour Gémeaux', () {
      final sign = getZodiacSign(DateTime(1990, 6, 15));
      expect(sign, 'GEMINI');
    });

    test('getZodiacSign retourne le bon signe pour Cancer', () {
      final sign = getZodiacSign(DateTime(1990, 7, 15));
      expect(sign, 'CANCER');
    });

    test('getZodiacSign retourne le bon signe pour Lion', () {
      final sign = getZodiacSign(DateTime(1990, 8, 10));
      expect(sign, 'LEO');
    });

    test('getZodiacSign retourne le bon signe pour Vierge', () {
      final sign = getZodiacSign(DateTime(1990, 9, 10));
      expect(sign, 'VIRGO');
    });

    test('getZodiacSign retourne le bon signe pour Balance', () {
      final sign = getZodiacSign(DateTime(1990, 10, 10));
      expect(sign, 'LIBRA');
    });

    test('getZodiacSign retourne le bon signe pour Scorpion', () {
      final sign = getZodiacSign(DateTime(1990, 11, 10));
      expect(sign, 'SCORPIO');
    });

    test('getZodiacSign retourne le bon signe pour Sagittaire', () {
      final sign = getZodiacSign(DateTime(1990, 12, 10));
      expect(sign, 'SAGITTARIUS');
    });

    test('getZodiacSign retourne le bon signe pour Capricorne', () {
      final sign = getZodiacSign(DateTime(1991, 1, 10));
      expect(sign, 'CAPRICORN');
    });

    test('getZodiacSign retourne le bon signe pour Verseau', () {
      final sign = getZodiacSign(DateTime(1990, 2, 10));
      expect(sign, 'AQUARIUS');
    });

    test('getZodiacSign retourne le bon signe pour Poissons', () {
      final sign = getZodiacSign(DateTime(1990, 3, 10));
      expect(sign, 'PISCES');
    });

    test('getZodiacSign gère les dates limites correctement', () {
      // Vérifier les transitions de signes
      final ariesStart = getZodiacSign(DateTime(1990, 3, 21));
      final piscesEnd = getZodiacSign(DateTime(1990, 3, 20));

      expect(ariesStart, 'ARIES');
      expect(piscesEnd, 'PISCES');
    });
  });
}
