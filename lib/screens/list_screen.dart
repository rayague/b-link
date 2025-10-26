import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/contact.dart';
import '../providers/contact_provider.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  @override
  void initState() {
    super.initState();
    final prov = Provider.of<ContactProvider>(context, listen: false);
    prov.loadContacts();
  }

  void _showAdd(BuildContext ctx) {
    final _name = TextEditingController();
    final _date = TextEditingController();
    final _relation = TextEditingController();
    final _phone = TextEditingController();
    String? _imagePath;
    final relations = ['SON','DAUGHTER','SISTER','BROTHER','FRIEND','NEIGHBOR','BESTFRIEND','BOYFRIEND','GIRLFRIEND','HUSBAND','FATHER','MOTHER','AUNTIE','UNCLE','COUSIN','NIECE','NEPHEW','GRAND-SON','GRAND-DAUGHTER','GRAND-FATHER','GRAND-MOTHER','GOD-FATHER','GOD-MOTHER'];

    showDialog(
      context: ctx,
      builder: (_) => StatefulBuilder(builder: (dialogCtx, setDialogState) => AlertDialog(
        title: const Text('Add contact'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height:8),
              TextField(
                controller: _date,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Date'),
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(context: dialogCtx, initialDate: now, firstDate: DateTime(1900), lastDate: DateTime(2100));
                  if (picked != null) setDialogState(() => _date.text = picked.toIso8601String().split('T').first);
                },
              ),
              const SizedBox(height:8),
              DropdownButtonFormField<String>(
                items: relations.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => _relation.text = v ?? '',
                decoration: const InputDecoration(labelText: 'Relation'),
              ),
              const SizedBox(height:8),
              TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone (optional)')),
              const SizedBox(height:8),
              Row(children: [
                _imagePath == null ? const CircleAvatar(radius:24, child: Icon(Icons.person)) : CircleAvatar(radius:24, backgroundImage: FileImage(File(_imagePath!))),
                const SizedBox(width:12),
                ElevatedButton.icon(onPressed: () async {
                  final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
                  if (img != null) setDialogState(() => _imagePath = img.path);
                }, icon: const Icon(Icons.photo), label: const Text('Pick'))
              ])
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            final name = _name.text.trim();
            final date = _date.text.trim();
            final relation = _relation.text.trim();
            if (name.isNotEmpty && date.isNotEmpty) {
              final c = Contact(name: name, date: date, relation: relation, phone: _phone.text.trim().isEmpty? null: _phone.text.trim(), imageUri: _imagePath);
              await Provider.of<ContactProvider>(context, listen: false).addContact(c);
              if (!mounted) return;
              // pop the dialog using the state context so the mounted check is relevant
              Navigator.of(context).pop();
            }
          }, child: const Text('Save'))
        ],
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<ContactProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Contacts')),
      body: prov.loading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
        itemCount: prov.contacts.length,
        itemBuilder: (_, i) {
          final c = prov.contacts[i];
          return ListTile(
            leading: CircleAvatar(child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?')),
            title: Text(c.name),
            subtitle: Text('${c.relation} • ${c.date}'),
            onTap: () => Navigator.of(context).pushNamed('/detail', arguments: c),
            trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
              if (c.id != null) await prov.deleteContact(c.id!);
            }),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _showAdd(context), child: const Icon(Icons.add)),
    );
  }
}

