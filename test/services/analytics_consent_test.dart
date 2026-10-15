import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:b_link/services/analytics_service.dart';

/// Firebase n'est pas initialisé dans les tests : le SDK est indisponible,
/// ce qui permet de vérifier la logique de consentement seule.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('consent is undecided on first launch', () async {
    SharedPreferences.setMockInitialValues({});
    final analytics = AnalyticsService();
    await analytics.loadConsent();
    expect(analytics.consent, isNull);
    expect(analytics.needsConsentDecision, isTrue);
  });

  test('the choice is remembered across launches', () async {
    SharedPreferences.setMockInitialValues({});
    final analytics = AnalyticsService();
    await analytics.setConsent(false);

    await analytics.loadConsent(); // relance de l'app
    expect(analytics.consent, isFalse);
    expect(analytics.needsConsentDecision, isFalse);

    await analytics.setConsent(true);
    await analytics.loadConsent();
    expect(analytics.consent, isTrue);
  });

  test('logging without consent never throws (events are dropped)', () async {
    SharedPreferences.setMockInitialValues(
        {AnalyticsService.consentPrefsKey: false});
    final analytics = AnalyticsService();
    await analytics.loadConsent();
    await analytics.logContactAdded(relation: 'friend');
    await analytics.setUserId('u1');
  });
}
