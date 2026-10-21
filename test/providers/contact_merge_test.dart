import 'package:flutter_test/flutter_test.dart';
import 'package:b_link/models/contact.dart';
import 'package:b_link/providers/contact_provider.dart';

Contact _c(String name, {int? id, String? uuid, String date = '1990-05-01'}) =>
    Contact(id: id, uuid: uuid, name: name, date: date, relation: 'friend');

void main() {
  test('newUuid produces distinct RFC 4122 v4 identifiers', () {
    final v4 = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
    final ids = List.generate(200, (_) => Contact.newUuid());
    expect(ids.every(v4.hasMatch), isTrue);
    expect(ids.toSet().length, ids.length);
  });

  group('planMerge', () {
    test('same uuid on both sides: nothing to do', () {
      final plan = ContactProvider.planMerge(
          [_c('Alice', id: 1, uuid: 'a')], [_c('Alice', uuid: 'a')]);
      expect(plan.insertLocally, isEmpty);
      expect(plan.upload, isEmpty);
      expect(plan.deleteRemote, isEmpty);
      expect(plan.adoptUuid, isEmpty);
    });

    test('two devices with different local ids no longer overwrite each other',
        () {
      // Avant : contact n°1 du téléphone A et n°1 du téléphone B = même
      // document Firestore "1". Maintenant chacun a son UUID.
      final plan = ContactProvider.planMerge(
        [_c('Alice', id: 1, uuid: 'uuid-a')],
        [_c('Bob', uuid: 'uuid-b', date: '1985-02-03')],
      );
      expect(plan.insertLocally.single.name, 'Bob');
      expect(plan.upload.single.uuid, 'uuid-a');
    });

    test('migrated contacts keep matching their legacy Firestore documents', () {
      // Migration v4 : uuid = ancien id ("3"), qui était l'ID du document.
      final plan = ContactProvider.planMerge(
          [_c('Alice', id: 3, uuid: '3')], [_c('Alice', uuid: '3')]);
      expect(plan.upload, isEmpty);
      expect(plan.insertLocally, isEmpty);
    });

    test('legacy timestamp duplicate is deleted remotely', () {
      final plan = ContactProvider.planMerge(
        [_c('Alice', id: 3, uuid: '3')],
        [_c('Alice', uuid: '3'), _c('Alice', uuid: '1728912345678')],
      );
      expect(plan.deleteRemote, ['1728912345678']);
      expect(plan.insertLocally, isEmpty);
    });

    test('the same contact created on two devices converges without looping',
        () {
      // Téléphone B a "Maman" (uuid-b), Firebase a "Maman" de A (uuid-a).
      final onB = ContactProvider.planMerge(
          [_c('Maman', id: 7, uuid: 'uuid-b')], [_c('Maman', uuid: 'uuid-a')]);
      expect(onB.adoptUuid, {7: 'uuid-a'});
      expect(onB.upload, isEmpty);
      expect(onB.deleteRemote, isEmpty);

      // Synchro suivante sur A : rien à faire, l'état est stable.
      final onA = ContactProvider.planMerge(
          [_c('Maman', id: 2, uuid: 'uuid-a')], [_c('Maman', uuid: 'uuid-a')]);
      expect(onA.adoptUuid, isEmpty);
      expect(onA.upload, isEmpty);
      expect(onA.deleteRemote, isEmpty);
    });

    test('a contact only on this device is uploaded', () {
      final plan = ContactProvider.planMerge([_c('Eve', id: 5, uuid: 'e')], []);
      expect(plan.upload.single.uuid, 'e');
    });

    test('identical local contacts are merged into the oldest one', () {
      // 8 fiches « hj » identiques (double import, ancien bug).
      final local = [
        for (var i = 1; i <= 8; i++) _c('hj', id: i, uuid: 'u$i'),
      ];
      final remote = [for (var i = 1; i <= 8; i++) _c('hj', uuid: 'u$i')];
      final plan = ContactProvider.planMerge(local, remote);
      expect(plan.deleteLocal.map((c) => c.id), [2, 3, 4, 5, 6, 7, 8]);
      expect(plan.deleteRemote, ['u2', 'u3', 'u4', 'u5', 'u6', 'u7', 'u8']);
      expect(plan.insertLocally, isEmpty);
      expect(plan.upload, isEmpty);
    });

    test('identical remote documents are inserted only once', () {
      final plan = ContactProvider.planMerge(
          [], [_c('hj', uuid: 'a'), _c('hj', uuid: 'b'), _c('hj', uuid: 'c')]);
      expect(plan.insertLocally.single.uuid, 'a');
      expect(plan.deleteRemote, ['b', 'c']);
    });

    test('same name and date but another relation is not a duplicate', () {
      final plan = ContactProvider.planMerge([
        _c('Sam', id: 1, uuid: 'a'),
        Contact(id: 2, uuid: 'b', name: 'Sam', date: '1990-05-01', relation: 'brother'),
      ], []);
      expect(plan.deleteLocal, isEmpty);
    });
  });
}
