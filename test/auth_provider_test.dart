import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  late MockFirebaseAuth mockAuth;

  setUp(() {
    mockAuth = MockFirebaseAuth(signedIn: false);
  });

  group('AuthProvider Firebase Tests', () {
    test('should initially have no Firebase user', () {
      expect(mockAuth.currentUser, isNull);
    });

    test('should sign in with credential (Google flow)', () async {
      // Simulate the Firebase credential sign-in that happens after Google auth
      final credential = GoogleAuthProvider.credential(
        idToken: 'mock-id-token',
      );
      final userCred = await mockAuth.signInWithCredential(credential);
      expect(userCred.user, isNotNull);
      expect(mockAuth.currentUser, isNotNull);
    });

    test('should clear user when sign out', () async {
      // Sign in first
      final credential = GoogleAuthProvider.credential(
        idToken: 'mock-id-token',
      );
      await mockAuth.signInWithCredential(credential);
      expect(mockAuth.currentUser, isNotNull);

      // Sign out should clear user
      await mockAuth.signOut();
      expect(mockAuth.currentUser, isNull);
    });

    test('should sign in anonymously', () async {
      final userCred = await mockAuth.signInAnonymously();
      expect(userCred.user, isNotNull);
      expect(mockAuth.currentUser, isNotNull);
    });
  });

  group('Email Validation Tests', () {
    test('should validate correct email format', () {
      final validEmails = [
        'test@example.com',
        'user.name@example.co.uk',
        'user+tag@example.com',
      ];

      for (var email in validEmails) {
        expect(_isValidEmail(email), isTrue, reason: '$email should be valid');
      }
    });

    test('should reject invalid email format', () {
      final invalidEmails = [
        'not-an-email',
        '@example.com',
        'user@',
        'user @example.com',
      ];

      for (var email in invalidEmails) {
        expect(_isValidEmail(email), isFalse,
            reason: '$email should be invalid');
      }
    });
  });
}

bool _isValidEmail(String email) {
  final emailRegex = RegExp(r'^[\w\+\-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return emailRegex.hasMatch(email);
}
