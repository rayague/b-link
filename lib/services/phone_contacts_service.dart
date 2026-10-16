import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;

import '../models/contact.dart';
import '../utils/birthday.dart';

/// Un contact du carnet du téléphone, candidat à l'import.
@immutable
class PhoneContact {
  final String id;
  final String name;
  final String? phone;

  /// Anniversaire du carnet (année [unknownBirthYear] si elle n'y est pas).
  final DateTime? birthday;

  const PhoneContact(
      {required this.id, required this.name, this.phone, this.birthday});

  PhoneContact withBirthday(DateTime date) =>
      PhoneContact(id: id, name: name, phone: phone, birthday: date);
}

/// Accès au carnet d'adresses du téléphone : lecture pour l'import,
/// création d'une fiche par l'éditeur du système (sans permission).
class PhoneContactsService {
  /// Demande la lecture du carnet. Renvoie l'état obtenu.
  Future<fc.PermissionStatus> requestRead() =>
      fc.FlutterContacts.permissions.request(fc.PermissionType.read);

  Future<void> openSettings() => fc.FlutterContacts.permissions.openSettings();

  static bool isGranted(fc.PermissionStatus s) =>
      s == fc.PermissionStatus.granted || s == fc.PermissionStatus.limited;

  /// Contacts du carnet (nom, téléphone, anniversaire), triés par nom.
  Future<List<PhoneContact>> load() async {
    final raw = await fc.FlutterContacts.getAll(properties: const {
      fc.ContactProperty.name,
      fc.ContactProperty.phone,
      fc.ContactProperty.event,
    });
    final list = raw.map(fromPlatform).whereType<PhoneContact>().toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  /// Conversion d'un contact du carnet (null s'il n'a pas de nom).
  @visibleForTesting
  static PhoneContact? fromPlatform(fc.Contact c) {
    final n = c.name;
    final composed = [n?.first, n?.last]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .join(' ');
    final name = (c.displayName?.trim().isNotEmpty ?? false)
        ? c.displayName!.trim()
        : composed.trim();
    if (name.isEmpty || c.id == null) return null;
    DateTime? birthday;
    for (final e in c.events) {
      if (e.label.label != fc.EventLabel.birthday) continue;
      if (e.month < 1 || e.month > 12 || e.day < 1 || e.day > 31) continue;
      birthday = DateTime(e.year ?? unknownBirthYear, e.month, e.day);
      break;
    }
    final phone = c.phones.isEmpty ? null : c.phones.first.number.trim();
    return PhoneContact(
      id: c.id!,
      name: name,
      phone: phone == null || phone.isEmpty ? null : phone,
      birthday: birthday,
    );
  }

  /// Contacts du carnet absents de B-Link (même nom ou même numéro).
  static List<PhoneContact> notImported(
      List<PhoneContact> phone, List<Contact> existing) {
    String key(String s) => s.trim().toLowerCase();
    String digits(String s) {
      final d = s.replaceAll(RegExp(r'\D'), '');
      // Les 9 derniers chiffres : ignore l'indicatif (+33 / 0).
      return d.length > 9 ? d.substring(d.length - 9) : d;
    }

    final names = {for (final c in existing) key(c.name)};
    final numbers = {
      for (final c in existing)
        if (c.phone != null && digits(c.phone!).length >= 6) digits(c.phone!),
    };
    return [
      for (final p in phone)
        if (!names.contains(key(p.name)) &&
            !(p.phone != null && numbers.contains(digits(p.phone!))))
          p,
    ];
  }

  /// Ouvre l'éditeur de contacts du téléphone, pré-rempli. Renvoie true si
  /// la fiche a été enregistrée.
  Future<bool> openCreator(Contact contact) async {
    final birth = parseBirthDate(contact.date);
    final parts = contact.name.trim().split(RegExp(r'\s+'));
    final id = await fc.FlutterContacts.native.showCreator(
      contact: fc.Contact(
        name: fc.Name(
          first: parts.first,
          last: parts.length > 1 ? parts.skip(1).join(' ') : null,
        ),
        phones: [
          if (contact.phone?.trim().isNotEmpty ?? false)
            fc.Phone(number: contact.phone!.trim()),
        ],
        events: [
          if (birth != null)
            fc.Event(
              year: hasBirthYear(birth) ? birth.year : null,
              month: birth.month,
              day: birth.day,
              label: const fc.Label(fc.EventLabel.birthday),
            ),
        ],
      ),
    );
    return id != null;
  }
}
