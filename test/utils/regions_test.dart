import 'package:b_link/utils/regions.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every country of the picker belongs to a region', () {
    const none = {'AQ', 'BV', 'HM', 'TF'}; // terres australes inhabitées
    final missing = [
      for (final c in CountryService().getAll())
        if (!none.contains(c.countryCode) && regionOf(c.countryCode) == null)
          c.countryCode,
    ];
    expect(missing, isEmpty);
  });

  test('a few well-known countries', () {
    expect(regionOf('bj'), 'AF');
    expect(regionOf('JP'), 'AS');
    expect(regionOf('DE'), 'EU');
    expect(regionOf('MX'), 'NA');
    expect(regionOf('AR'), 'SA');
    expect(regionOf('NZ'), 'OC');
    expect(regionOf(null), isNull);
  });
}
