import 'dart:math';

class Contact {
  /// ID SQLite local : clé de la base et des IDs de notification.
  final int? id;

  /// Identifiant stable entre appareils : ID du document Firestore. Les
  /// contacts créés avant son introduction reçoivent leur ancien ID local
  /// ("1", "2"...), qui était aussi leur ID Firestore.
  final String? uuid;

  final String name;
  final String date; // ISO 8601
  final String relation;
  final String? imageUri;
  final String? phone;

  Contact(
      {this.id,
      this.uuid,
      required this.name,
      required this.date,
      required this.relation,
      this.imageUri,
      this.phone});

  /// [clearId] retire l'ID local (contact venant d'un autre appareil).
  Contact copyWith({int? id, String? uuid, bool clearId = false}) => Contact(
      id: clearId ? null : (id ?? this.id),
      uuid: uuid ?? this.uuid,
      name: name,
      date: date,
      relation: relation,
      imageUri: imageUri,
      phone: phone);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid,
      'name': name,
      'date': date,
      'relation': relation,
      'imageUri': imageUri,
      'phone': phone,
    };
  }

  // Alias pour Firebase
  Map<String, dynamic> toJson() => toMap();

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'] as int?,
      uuid: map['uuid'] as String?,
      name: map['name'] as String? ?? '',
      date: map['date'] as String? ?? '',
      relation: map['relation'] as String? ?? '',
      imageUri: map['imageUri'] as String?,
      phone: map['phone'] as String?,
    );
  }

  // Alias pour Firebase
  factory Contact.fromJson(Map<String, dynamic> json) => Contact.fromMap(json);

  static final Random _random = Random.secure();

  /// UUID v4 (RFC 4122) aléatoire.
  static String newUuid() {
    final b = List<int>.generate(16, (_) => _random.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40; // version 4
    b[8] = (b[8] & 0x3f) | 0x80; // variante RFC 4122
    String hex(int from, int to) => b
        .sublist(from, to)
        .map((x) => x.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }
}
