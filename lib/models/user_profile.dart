import 'dart:convert';

class UserProfile {
  String? uid;
  String name;
  String? givenName;
  String? familyName;
  DateTime birthDate; // date with year, month, day
  String? birthTime; // e.g. 14:30
  String? timezone;
  String? zodiac;
  String? birthplace; // Ville de naissance
  String? birthCountry; // Pays de naissance
  String? birthCity; // Ville actuelle
  Map<String, String>? socialLinks; // platform -> url
  String? bio;
  DateTime? lastSyncedAt;

  // Privacy settings
  bool isPublic;
  bool publicName;
  bool publicBirthDate;
  bool publicBirthTime;
  bool publicBirthPlace;
  bool publicBirthCountry;
  bool publicBirthCity;
  bool publicSocials;
  bool publicZodiac;

  String? birthDayKey; // MM-DD for indexing

  UserProfile({
    this.uid,
    required this.name,
    this.givenName,
    this.familyName,
    required this.birthDate,
    this.birthTime,
    this.timezone,
    this.zodiac,
    this.birthplace,
    this.birthCountry,
    this.birthCity,
    this.socialLinks,
    this.bio,
    this.lastSyncedAt,
    this.isPublic = false,
    this.publicName = false,
    this.publicBirthDate = false,
    this.publicBirthTime = false,
    this.publicBirthPlace = false,
    this.publicBirthCountry = false,
    this.publicBirthCity = false,
    this.publicSocials = false,
    this.publicZodiac = false,
    this.birthDayKey,
  });

  // ✅ UNE SEULE méthode fromMap avec TOUS les champs
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    // Helper pour conversion booléenne
    bool toBool(dynamic value) {
      if (value is bool) return value;
      if (value is int) return value == 1;
      return false;
    }

    return UserProfile(
      uid: map['uid'] as String?,
      name: map['name'] as String? ?? 'Anonymous',
      givenName: map['givenName'] as String?,
      familyName: map['familyName'] as String?,
      birthDate: DateTime.parse(map['birthDate'] as String),
      birthTime: map['birthTime'] as String?,
      timezone: map['timezone'] as String?,
      zodiac: map['zodiac'] as String?,
      birthplace: map['birthplace'] as String?,
      birthCountry: map['birthCountry'] as String?,
      birthCity: map['birthCity'] as String?,
      socialLinks: map['socialLinks'] == null
          ? null
          : Map<String, String>.from(map['socialLinks'] as Map),
      bio: map['bio'] as String?,
      lastSyncedAt: map['lastSyncedAt'] == null
          ? null
          : DateTime.tryParse(map['lastSyncedAt'] as String),
      isPublic: toBool(map['isPublic']),
      publicName: toBool(map['publicName']),
      publicBirthDate: toBool(map['publicBirthDate']),
      publicBirthTime: toBool(map['publicBirthTime']),
      publicBirthPlace: toBool(map['publicBirthPlace']),
      publicBirthCountry: toBool(map['publicBirthCountry']),
      publicBirthCity: toBool(map['publicBirthCity']),
      publicSocials: toBool(map['publicSocials']),
      publicZodiac: toBool(map['publicZodiac']),
      birthDayKey: map['birthDayKey'] as String?,
    );
  }

  // fromJson utilise maintenant fromMap pour éviter la duplication
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile.fromMap(json);
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'givenName': givenName,
        'familyName': familyName,
        'birthDate': birthDate.toIso8601String(),
        'birthTime': birthTime,
        'timezone': timezone,
        'zodiac': zodiac,
        'birthplace': birthplace,
        'birthCountry': birthCountry,
        'birthCity': birthCity,
        'socialLinks': socialLinks,
        'bio': bio,
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
        'isPublic': isPublic,
        'publicName': publicName,
        'publicBirthDate': publicBirthDate,
        'publicBirthTime': publicBirthTime,
        'publicBirthPlace': publicBirthPlace,
        'publicBirthCountry': publicBirthCountry,
        'publicBirthCity': publicBirthCity,
        'publicSocials': publicSocials,
        'publicZodiac': publicZodiac,
        'birthDayKey': birthDayKey,
      };

  // Alias de toJson pour compatibilité
  Map<String, dynamic> toMap() => toJson();

  String toEncodedJson() => json.encode(toJson());
}
