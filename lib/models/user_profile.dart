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
  String? birthplace;
  Map<String, String>? socialLinks; // platform -> url
  String? bio;
  DateTime? lastSyncedAt;
  bool isPublic;
  bool publicName;
  bool publicBirthDate;
  bool publicBirthPlace;
  bool publicSocials;
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
    this.socialLinks,
    this.bio,
    this.lastSyncedAt,
    this.isPublic = false,
    this.publicName = false,
    this.publicBirthDate = false,
    this.publicBirthPlace = false,
    this.publicSocials = false,
    this.birthDayKey,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        uid: json['uid'] as String?,
    name: json['name'] as String? ?? '',
    givenName: json['givenName'] as String?,
    familyName: json['familyName'] as String?,
    birthDate: DateTime.parse(json['birthDate'] as String),
        birthTime: json['birthTime'] as String?,
        timezone: json['timezone'] as String?,
        zodiac: json['zodiac'] as String?,
    birthplace: json['birthplace'] as String?,
    socialLinks: json['socialLinks'] == null
            ? null
            : Map<String, String>.from(json['socialLinks'] as Map),
        bio: json['bio'] as String?,
        lastSyncedAt: json['lastSyncedAt'] == null
            ? null
            : DateTime.parse(json['lastSyncedAt'] as String),
    isPublic: json['isPublic'] == null ? false : json['isPublic'] as bool,
    publicName: json['publicName'] == null ? false : json['publicName'] as bool,
    publicBirthDate: json['publicBirthDate'] == null ? false : json['publicBirthDate'] as bool,
    publicBirthPlace: json['publicBirthPlace'] == null ? false : json['publicBirthPlace'] as bool,
    publicSocials: json['publicSocials'] == null ? false : json['publicSocials'] as bool,
    birthDayKey: json['birthDayKey'] as String?,
      );

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
        'socialLinks': socialLinks,
        'bio': bio,
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    'isPublic': isPublic,
    'publicName': publicName,
    'publicBirthDate': publicBirthDate,
    'publicBirthPlace': publicBirthPlace,
    'publicSocials': publicSocials,
    'birthDayKey': birthDayKey,
      };

  String toEncodedJson() => json.encode(toJson());
}
