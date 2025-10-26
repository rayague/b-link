import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../models/contact.dart';
import '../providers/contact_provider.dart';

class ContactDetailScreen extends StatefulWidget {
  const ContactDetailScreen({super.key});

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  final _name = TextEditingController();
  final _date = TextEditingController();
  final _relation = TextEditingController();
  final _phone = TextEditingController();
  String? _imagePath;
  final relations = ['SON','DAUGHTER','SISTER','BROTHER','FRIEND','NEIGHBOR','BESTFRIEND','BOYFRIEND','GIRLFRIEND','HUSBAND','FATHER','MOTHER','AUNTIE','UNCLE','COUSIN','NIECE','NEPHEW','GRAND-SON','GRAND-DAUGHTER','GRAND-FATHER','GRAND-MOTHER','GOD-FATHER','GOD-MOTHER'];
  Contact? _contact;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)!.settings.arguments;
    if (arg is Contact) {
      _contact = arg;
  _name.text = _contact!.name;
  _date.text = _contact!.date;
  _relation.text = _contact!.relation;
  _phone.text = _contact!.phone ?? '';
  _imagePath = _contact!.imageUri;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_contact == null) return const Scaffold(body: Center(child: Text('No contact')));
    return Scaffold(
      appBar: AppBar(title: Text(_contact!.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height:8),
            TextField(
              controller: _date,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Date'),
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(context: context, initialDate: now, firstDate: DateTime(1900), lastDate: DateTime(2100));
                if (picked != null) _date.text = picked.toIso8601String().split('T').first;
              },
            ),
            const SizedBox(height:8),
            DropdownButtonFormField<String>(
              initialValue: _relation.text.isEmpty? null: _relation.text,
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
                if (img != null) setState(() => _imagePath = img.path);
              }, icon: const Icon(Icons.photo), label: const Text('Pick'))
            ]),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () async {
              final updated = Contact(id: _contact!.id, name: _name.text.trim(), date: _date.text.trim(), relation: _relation.text.trim(), imageUri: _imagePath, phone: _phone.text.trim().isEmpty? null: _phone.text.trim());
              await Provider.of<ContactProvider>(context, listen: false).updateContact(updated);
              if (!mounted) return;
              Navigator.of(context).pop();
            }, child: const Text('Update'))
          ],
        ),
      ),
    );
  }
}
