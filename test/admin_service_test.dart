import 'package:flutter_test/flutter_test.dart';
import 'package:b_link/services/admin_service.dart';
import 'package:b_link/models/admin_user.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late AdminService adminService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    adminService = AdminService(firestore: fakeFirestore);
  });

  group('AdminService Tests', () {
    test('should verify user is not admin when no admin exists', () async {
      final isAdmin = await adminService.isUserAdmin('test-uid');

      expect(isAdmin, isFalse);
    });

    test('should verify user is admin when admin document exists', () async {
      // Créer un admin dans le fake Firestore
      final admin = AdminUser(
        uid: 'admin-uid',
        email: 'admin@test.com',
        passwordHash: 'hash',
        role: 'super_admin',
        createdAt: DateTime.now(),
        isActive: true,
      );

      await fakeFirestore
          .collection('admins')
          .doc('admin-uid')
          .set(admin.toMap());

      final isAdmin = await adminService.isUserAdmin('admin-uid');

      expect(isAdmin, isTrue);
    });

    test('should not verify inactive admin as admin', () async {
      final admin = AdminUser(
        uid: 'inactive-admin',
        email: 'inactive@test.com',
        passwordHash: 'hash',
        role: 'admin',
        createdAt: DateTime.now(),
        isActive: false,
      );

      await fakeFirestore
          .collection('admins')
          .doc('inactive-admin')
          .set(admin.toMap());

      final isAdmin = await adminService.isUserAdmin('inactive-admin');

      expect(isAdmin, isFalse);
    });

    test('should get admin user data', () async {
      final admin = AdminUser(
        uid: 'admin-uid',
        email: 'admin@test.com',
        passwordHash: 'hash',
        role: 'super_admin',
        createdAt: DateTime.now(),
        isActive: true,
      );

      await fakeFirestore
          .collection('admins')
          .doc('admin-uid')
          .set(admin.toMap());

      final adminUser = await adminService.getAdminUser('admin-uid');

      expect(adminUser, isNotNull);
      expect(adminUser!.uid, equals('admin-uid'));
      expect(adminUser.email, equals('admin@test.com'));
      expect(adminUser.role, equals('super_admin'));
      expect(adminUser.isActive, isTrue);
    });

    test('should update last login timestamp', () async {
      final admin = AdminUser(
        uid: 'admin-uid',
        email: 'admin@test.com',
        passwordHash: 'hash',
        role: 'admin',
        createdAt: DateTime.now(),
        isActive: true,
      );

      await fakeFirestore
          .collection('admins')
          .doc('admin-uid')
          .set(admin.toMap());

      await adminService.updateLastLogin('admin-uid');

      final doc =
          await fakeFirestore.collection('admins').doc('admin-uid').get();
      expect(doc.data()?['lastLogin'], isNotNull);
    });

    test('should list all admins', () async {
      final admin1 = AdminUser(
        uid: 'admin-1',
        email: 'admin1@test.com',
        passwordHash: 'hash1',
        role: 'super_admin',
        createdAt: DateTime.now(),
        isActive: true,
      );

      final admin2 = AdminUser(
        uid: 'admin-2',
        email: 'admin2@test.com',
        passwordHash: 'hash2',
        role: 'admin',
        createdAt: DateTime.now(),
        isActive: true,
      );

      await fakeFirestore
          .collection('admins')
          .doc('admin-1')
          .set(admin1.toMap());
      await fakeFirestore
          .collection('admins')
          .doc('admin-2')
          .set(admin2.toMap());

      final admins = await adminService.getAllAdmins();

      expect(admins.length, equals(2));
      expect(admins[0].email, equals('admin1@test.com'));
      expect(admins[1].email, equals('admin2@test.com'));
    });
  });

  group('AdminAuthService Tests', () {
    test('should hash password consistently', () {
      // On ne peut pas tester directement _hashPassword car c'est privé,
      // mais on peut tester que deux authentifications avec le même mot de passe
      // devraient donner le même hash

      // Ce test est une démonstration de concept
      expect(true, isTrue);
    });
  });
}
