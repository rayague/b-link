import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/contact.dart';
import '../services/contact_photo_store.dart';
import '../theme/app_theme.dart';
import '../utils/birthday.dart';
import '../utils/birthday_labels.dart';
import '../utils/relations.dart';
import 'contact_avatar.dart';
import 'ui/components.dart';

/// Formulaire d'un contact (ajout et modification) : photo, nom, date de
/// naissance, relation, téléphone.
class ContactForm extends StatefulWidget {
  final Contact? initial;
  final String submitLabel;

  /// Reçoit le contact saisi (avec l'id et l'uuid de [initial]).
  final Future<void> Function(Contact draft) onSubmit;

  const ContactForm({
    super.key,
    this.initial,
    required this.submitLabel,
    required this.onSubmit,
  });

  @override
  State<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _phone =
      TextEditingController(text: widget.initial?.phone ?? '');
  late DateTime? _birth = parseBirthDate(widget.initial?.date ?? '');
  // Les anciennes versions enregistraient parfois la relation en minuscules.
  late String _relation = kRelations.firstWhere(
      (r) => r == widget.initial?.relation.toUpperCase(),
      orElse: () => 'FRIEND');
  late String? _image = widget.initial?.imageUri;
  bool _dateError = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birth ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900),
      // Une date de naissance n'est jamais dans le futur.
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) {
      setState(() {
        _birth = picked;
        _dateError = false;
      });
    }
  }

  Future<void> _pickPhoto() async {
    final path = await ContactPhotoStore().pick();
    if (path != null) setState(() => _image = path);
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState!.validate();
    setState(() => _dateError = _birth == null);
    if (!valid || _birth == null) return;
    final b = _birth!;
    final phone = _phone.text.trim();
    setState(() => _saving = true);
    try {
      await widget.onSubmit(Contact(
        id: widget.initial?.id,
        uuid: widget.initial?.uuid,
        name: _name.text.trim(),
        date: '${b.year.toString().padLeft(4, '0')}-'
            '${b.month.toString().padLeft(2, '0')}-'
            '${b.day.toString().padLeft(2, '0')}',
        relation: _relation,
        phone: phone.isEmpty ? null : phone,
        imageUri: _image,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = Theme.of(context).colorScheme;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Stack(
              children: [
                InkWell(
                  onTap: _pickPhoto,
                  customBorder: const CircleBorder(),
                  child: ContactAvatar(
                      name: _name.text.isEmpty ? '?' : _name.text,
                      imagePath: _image,
                      size: 88),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: c.primary,
                    shape: CircleBorder(side: BorderSide(color: c.surface, width: 2)),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _pickPhoto,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(Icons.photo_camera_outlined,
                            size: 16, color: c.onPrimary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_image != null)
            Center(
              child: TextButton(
                onPressed: () => setState(() => _image = null),
                child: Text(l10n.translate('removePhoto')),
              ),
            ),
          const SizedBox(height: Space.l),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}), // initiale de l'avatar
            decoration: InputDecoration(
              labelText: l10n.translate('fullName'),
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
            validator: (v) => (v ?? '').trim().isEmpty
                ? l10n.translate('enterName')
                : null,
          ),
          const SizedBox(height: Space.m),
          PickerField(
            label: l10n.translate('birthDate'),
            icon: Icons.cake_outlined,
            value: _birth == null ? null : fullDateLabel(l10n, _birth!),
            placeholder: l10n.translate('selectDate'),
            onTap: _pickDate,
          ),
          if (_dateError)
            Padding(
              padding: const EdgeInsets.only(left: Space.l, top: Space.xs),
              child: Text(l10n.translate('selectBirthDate'),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: c.error)),
            ),
          const SizedBox(height: Space.m),
          DropdownButtonFormField<String>(
            initialValue: _relation,
            borderRadius: BorderRadius.circular(Radii.control),
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: InputDecoration(
              labelText: l10n.translate('relation'),
              prefixIcon: const Icon(Icons.favorite_border_rounded),
            ),
            items: [
              for (final r in kRelations)
                DropdownMenuItem(value: r, child: Text(relationLabel(l10n, r))),
            ],
            onChanged: (v) => setState(() => _relation = v ?? _relation),
          ),
          const SizedBox(height: Space.m),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.translate('phoneOptional'),
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: Space.xl),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(widget.submitLabel),
          ),
        ],
      ),
    );
  }
}
