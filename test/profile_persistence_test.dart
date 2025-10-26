import 'package:flutter_test/flutter_test.dart';
import 'package:b_link/models/user_profile.dart';
import 'package:b_link/services/profile_service.dart';

void main() {
  test('save and load profile using SharedPreferences wrapper', () async {
    final svc = ProfileService();
    final profile = UserProfile(name: 'Test', birthDate: DateTime(1990,1,1));
    await svc.saveLocally(profile);
    final loaded = await svc.loadLocal();
    expect(loaded, isNotNull);
    expect(loaded!.name, 'Test');
    expect(loaded.birthDate.year, 1990);
  });
}
