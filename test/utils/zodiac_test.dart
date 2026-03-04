import 'package:flutter_test/flutter_test.dart';
import 'package:b_link/utils/zodiac.dart';

void main() {
  group('Zodiac Utils Tests', () {
    test('computeZodiac retourne le bon signe pour Bélier', () {
      final sign = Zodiac.computeZodiac(DateTime(1990, 3, 21));
      expect(sign, 'Bélier');
    });

    test('computeZodiac retourne le bon signe pour Taureau', () {
      final sign = Zodiac.computeZodiac(DateTime(1990, 5, 10));
      expect(sign, 'Taureau');
    });

    test('computeZodiac retourne le bon signe pour Gémeaux', () {
      final sign = Zodiac.computeZodiac(DateTime(1990, 6, 15));
      expect(sign, 'Gémeaux');
    });

    test('computeZodiac retourne le bon signe pour Cancer', () {
      final sign = Zodiac.computeZodiac(DateTime(1990, 7, 15));
      expect(sign, 'Cancer');
    });

    test('computeZodiac retourne le bon signe pour Lion', () {
      final sign = Zodiac.computeZodiac(DateTime(1990, 8, 10));
      expect(sign, 'Lion');
    });

    test('computeZodiac retourne le bon signe pour Vierge', () {
      final sign = Zodiac.computeZodiac(DateTime(1990, 9, 10));
      expect(sign, 'Vierge');
    });

    test('computeZodiac retourne le bon signe pour Balance', () {
      final sign = Zodiac.computeZodiac(DateTime(1990, 10, 10));
      expect(sign, 'Balance');
    });

    test('computeZodiac retourne le bon signe pour Scorpion', () {
      final sign = Zodiac.computeZodiac(DateTime(1990, 11, 10));
      expect(sign, 'Scorpion');
    });

    test('computeZodiac retourne le bon signe pour Sagittaire', () {
      final sign = Zodiac.computeZodiac(DateTime(1990, 12, 10));
      expect(sign, 'Sagittaire');
    });

    test('computeZodiac retourne le bon signe pour Capricorne', () {
      final sign = Zodiac.computeZodiac(DateTime(1991, 1, 10));
      expect(sign, 'Capricorne');
    });

    test('computeZodiac retourne le bon signe pour Verseau', () {
      final sign = Zodiac.computeZodiac(DateTime(1990, 2, 10));
      expect(sign, 'Verseau');
    });

    test('computeZodiac retourne le bon signe pour Poissons', () {
      final sign = Zodiac.computeZodiac(DateTime(1990, 3, 10));
      expect(sign, 'Poissons');
    });

    test('computeZodiac gère les dates limites correctement', () {
      // Vérifier les transitions de signes
      final ariesStart = Zodiac.computeZodiac(DateTime(1990, 3, 21));
      final piscesEnd = Zodiac.computeZodiac(DateTime(1990, 3, 20));

      expect(ariesStart, 'Bélier');
      expect(piscesEnd, 'Poissons');
    });
  });
}
