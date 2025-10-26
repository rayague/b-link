class Contact {
  final int? id;
  final String name;
  final String date; // ISO 8601
  final String relation;
  final String? imageUri;
  final String? phone;

  Contact({this.id, required this.name, required this.date, required this.relation, this.imageUri, this.phone});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date,
      'relation': relation,
      'imageUri': imageUri,
      'phone': phone,
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      date: map['date'] as String? ?? '',
      relation: map['relation'] as String? ?? '',
      imageUri: map['imageUri'] as String?,
      phone: map['phone'] as String?,
    );
  }
}

