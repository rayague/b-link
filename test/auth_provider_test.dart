import 'package:flutter_test/flutter_test.dart';
import 'package:b_link/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late AuthProvider authProvider;

  setUp(() {
    mockAuth = MockFirebaseAuth(signedIn: false);
    authProvider = AuthProvider();
  });

  group('AuthProvider Firebase Tests', () {
    test('should initially have no Firebase user', () {
      expect(mockAuth.currentUser, isNull);
    });

    test('should sign up and login with Firebase', () async {
      // Register
      final userCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      );
      expect(userCred.user, isNotNull);
      expect(userCred.user!.email, 'test@example.com');

      // Login
      await mockAuth.signOut();
      final loginCred = await mockAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      );
      expect(loginCred.user, isNotNull);
      expect(loginCred.user!.email, 'test@example.com');
    });

    test('should clear user when sign out', () async {
      final userCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      );
      expect(mockAuth.currentUser, isNotNull);
      await mockAuth.signOut();
      expect(mockAuth.currentUser, isNull);
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
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return emailRegex.hasMatch(email);
}
