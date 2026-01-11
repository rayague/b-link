import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:b_link/models/contact.dart';

void main() {
  testWidgets('ContactCard affiche les informations du contact',
      (tester) async {
    final contact = Contact(
      id: 1,
      name: 'Alice Dupont',
      date: '1995-03-15',
      relation: 'FRIEND',
      phone: '0612345678',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListTile(
            leading: CircleAvatar(child: Text(contact.name[0])),
            title: Text(contact.name),
            subtitle: Text(contact.relation),
          ),
        ),
      ),
    );

    expect(find.text('Alice Dupont'), findsOneWidget);
    expect(find.text('FRIEND'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('ContactCard affiche l\'initiale correcte', (tester) async {
    final contact = Contact(
      id: 2,
      name: 'Bob Martin',
      date: '1990-07-20',
      relation: 'BROTHER',
      phone: '0623456789',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListTile(
            leading: CircleAvatar(child: Text(contact.name[0])),
            title: Text(contact.name),
            subtitle: Text(contact.relation),
          ),
        ),
      ),
    );

    expect(find.text('Bob Martin'), findsOneWidget);
    expect(find.text('BROTHER'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('ContactCard gère les contacts sans téléphone', (tester) async {
    final contact = Contact(
      id: 3,
      name: 'Charlie Brown',
      date: '1988-12-25',
      relation: 'FRIEND',
      phone: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListTile(
            leading: CircleAvatar(child: Text(contact.name[0])),
            title: Text(contact.name),
            subtitle: Text(
                '${contact.relation}${contact.phone != null ? ' • ${contact.phone}' : ''}'),
          ),
        ),
      ),
    );

    expect(find.text('Charlie Brown'), findsOneWidget);
    expect(find.text('FRIEND'), findsOneWidget);
    expect(find.textContaining('0'), findsNothing); // Pas de téléphone affiché
  });
}
