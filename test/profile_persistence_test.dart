import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:b_link/models/user_profile.dart';
import 'package:b_link/services/profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('save and load profile using SharedPreferences wrapper', () async {
    // Setup mock SharedPreferences with empty initial values
    SharedPreferences.setMockInitialValues({});

    final svc = ProfileService();
    final profile = UserProfile(name: 'Test', birthDate: DateTime(1990,1,1));
    await svc.saveLocally(profile);
    final loaded = await svc.loadLocal();
    expect(loaded, isNotNull);
    expect(loaded!.name, 'Test');
    expect(loaded.birthDate.year, 1990);
  });
}
