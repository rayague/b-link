import 'package:b_link/models/contact.dart';
import 'package:b_link/services/phone_contacts_service.dart';
import 'package:b_link/utils/birthday.dart';
import 'package:b_link/utils/whatsapp.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhoneContactsService.fromPlatform', () {
    test('reads name, first phone and birthday', () {
      final c = PhoneContactsService.fromPlatform(const fc.Contact(
        id: '1',
        displayName: 'Léa Bernard',
        phones: [fc.Phone(number: ' 06 12 34 56 78 '), fc.Phone(number: '01')],
        events: [
          fc.Event(year: 2001, month: 6, day: 2),
          fc.Event(
              year: 1995,
              month: 3,
              day: 21,
              label: fc.Label(fc.EventLabel.birthday)),
        ],
      ))!;
      expect(c.name, 'Léa Bernard');
      expect(c.phone, '06 12 34 56 78');
      expect(c.birthday, DateTime(1995, 3, 21)); // pas l'autre évènement
    });

    test('a birthday without year keeps the day, year marked unknown', () {
      final c = PhoneContactsService.fromPlatform(const fc.Contact(
        id: '2',
        name: fc.Name(first: 'Hugo', last: 'Martin'),
        events: [
          fc.Event(month: 2, day: 29, label: fc.Label(fc.EventLabel.birthday))
        ],
      ))!;
      expect(c.name, 'Hugo Martin');
      expect(c.birthday!.month, 2);
      expect(c.birthday!.day, 29);
      expect(hasBirthYear(c.birthday!), isFalse);
    });

    test('contacts without a name are skipped', () {
      expect(
          PhoneContactsService.fromPlatform(
              const fc.Contact(id: '3', phones: [fc.Phone(number: '0612')])),
          isNull);
    });
  });

  test('notImported skips same name or same number', () {
    final phone = [
      const PhoneContact(id: 'a', name: 'Léa Bernard'),
      const PhoneContact(id: 'b', name: 'Maman', phone: '+33 6 12 34 56 78'),
      const PhoneContact(id: 'c', name: 'Noah'),
    ];
    final existing = [
      Contact(name: ' léa bernard', date: '1995-03-21', relation: 'FRIEND'),
      Contact(
          name: 'Mère',
          date: '1968-11-10',
          relation: 'MOTHER',
          phone: '06 12 34 56 78'),
    ];
    expect(PhoneContactsService.notImported(phone, existing).map((p) => p.id),
        ['c']);
  });

  group('whatsapp', () {
    test('national number gets the country code', () {
      expect(internationalDigits('06 12 34 56 78', '33'), '33612345678');
      expect(internationalDigits('97 12 34 56', '229'), '22997123456');
    });

    test('international formats are kept', () {
      expect(internationalDigits('+229 97 12 34 56', '33'), '22997123456');
      expect(internationalDigits('0033 6 12 34 56 78', null), '33612345678');
    });

    test('unknown country code: no number, WhatsApp lets the user choose', () {
      expect(internationalDigits('06 12 34 56 78', null), isNull);
      final uri = whatsappUri('Joyeux anniversaire !', phone: '0612345678');
      expect(uri.path, '/');
      expect(uri.queryParameters['text'], 'Joyeux anniversaire !');
    });

    test('link opens the conversation with the message', () {
      final uri = whatsappUri('Bon anniversaire & bises',
          phone: '06 12 34 56 78', dialCode: '33');
      expect(uri.toString(),
          'https://wa.me/33612345678?text=Bon+anniversaire+%26+bises');
    });
  });
}
