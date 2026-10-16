import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../l10n/zodiac_content.dart';
import '../models/contact.dart';
import '../providers/contact_provider.dart';
import '../providers/locale_provider.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';
import '../utils/birthday.dart';
import '../utils/birthday_labels.dart';
import '../utils/relations.dart';
import '../utils/zodiac.dart';
import '../widgets/contact_avatar.dart';
import '../widgets/contact_form.dart';
import '../widgets/message_sheet.dart';
import '../widgets/ui/components.dart';
import '../widgets/ui/glass.dart';

/// Fiche d'un contact : prochain anniversaire, message, appel, modification.
class ContactDetailScreen extends StatefulWidget {
  const ContactDetailScreen({super.key});

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  Contact? _initial;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView(screenName: 'ContactDetailScreen');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Lu une seule fois : didChangeDependencies est rappelé à chaque
    // changement de thème ou de langue.
    _initial ??= ModalRoute.of(context)?.settings.arguments as Contact?;
  }

  Future<void> _edit(Contact contact) {
    final l10n = AppLocalizations.of(context);
    final provider = context.read<ContactProvider>();
    final locale = context.read<LocaleProvider>().locale.languageCode;
    final messenger = ScaffoldMessenger.of(context);
    return showGlassSheet<void>(
      context,
      builder: (sheet) => SingleChildScrollView(
        padding:
            const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, Space.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.translate('editContact'),
                style: Theme.of(sheet).textTheme.titleLarge),
            const SizedBox(height: Space.l),
            ContactForm(
              initial: contact,
              submitLabel: l10n.translate('save'),
              onSubmit: (draft) async {
                await provider.updateContact(draft, locale: locale);
                if (!sheet.mounted) return;
                Navigator.of(sheet).pop();
                messenger.showSnackBar(SnackBar(
                    content: Text(l10n.translate('contactUpdated'))));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(Contact contact) async {
    final l10n = AppLocalizations.of(context);
    final provider = context.read<ContactProvider>();
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.translate('deleteContactTitle')),
        content: Text(l10n
            .translate('deleteContactBody')
            .replaceAll('{name}', contact.name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.translate('cancel'))),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.translate('delete')),
          ),
        ],
      ),
    );
    if (ok != true || contact.id == null) return;
    navigator.pop();
    await provider.deleteContact(contact.id!);
  }

  Future<void> _call(Contact contact) async {
    AnalyticsService()
        .logCallInitiated(relation: contact.relation, hasPhone: true);
    final uri = Uri(scheme: 'tel', path: contact.phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final initial = _initial;
    // Version à jour après une modification.
    final contact = initial?.id == null
        ? initial
        : context.watch<ContactProvider>().byId(initial!.id!) ?? initial;

    if (contact == null) {
      return AppScaffold(
        body: Center(
          child: EmptyState(
              icon: Icons.person_off_outlined,
              title: l10n.translate('contactNotFound')),
        ),
      );
    }

    final birth = parseBirthDate(contact.date);
    final now = DateTime.now();
    final days = birth == null ? null : daysUntilBirthday(birth, now);
    final age = birth == null ? null : ageAtNextBirthday(birth, now);
    final hasPhone = contact.phone?.trim().isNotEmpty == true;
    final sign = birth == null ? null : Zodiac.computeZodiac(birth);

    return AppScaffold(
      actions: [
        IconButton(
          tooltip: l10n.translate('edit'),
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => _edit(contact),
        ),
        PopupMenuButton<String>(
          onSelected: (_) => _delete(contact),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'delete',
              child: Text(l10n.translate('delete'),
                  style: TextStyle(color: c.error)),
            ),
          ],
        ),
      ],
      body: ListView(
        padding: AppScaffold.pagePadding(context),
        children: [
          GlassCard(
            padding: const EdgeInsets.all(Space.xl),
            tint: days == 0 ? c.secondary : null,
            child: Column(
              children: [
                ContactAvatar(
                    name: contact.name, imagePath: contact.imageUri, size: 88),
                const SizedBox(height: Space.l),
                Text(contact.name,
                    style: t.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: Space.s),
                Pill(relationLabel(l10n, contact.relation)),
                if (days != null) ...[
                  const SizedBox(height: Space.xl),
                  if (days == 0)
                    Text(
                      age == null
                          ? l10n.translate('birthdayToday')
                          : l10n
                              .translate('turnsAgeToday')
                              .replaceAll('{age}', '$age'),
                      style: t.titleMedium?.copyWith(color: c.secondary),
                      textAlign: TextAlign.center,
                    )
                  else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('$days',
                            style: t.displaySmall?.copyWith(color: c.primary)),
                        const SizedBox(width: Space.s),
                        Text(l10n.translate(days == 1 ? 'dayLeft' : 'daysLeft'),
                            style: t.bodyLarge
                                ?.copyWith(color: c.onSurfaceVariant)),
                      ],
                    ),
                    if (age != null)
                      Text(
                        l10n.translate('willTurnAge').replaceAll('{age}', '$age'),
                        style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant),
                      ),
                  ],
                ],
                const SizedBox(height: Space.xl),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => showBirthdayMessageSheet(context,
                            name: contact.name, relation: contact.relation),
                        icon: const Icon(Icons.edit_note_rounded),
                        label: Text(l10n.translate('writeMessage')),
                      ),
                    ),
                    if (hasPhone) ...[
                      const SizedBox(width: Space.s),
                      IconButton.outlined(
                        tooltip: l10n.translate('call'),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(52, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(Radii.control)),
                          side: BorderSide(color: c.outline),
                        ),
                        onPressed: () => _call(contact),
                        icon: const Icon(Icons.call_outlined),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.m),
          GlassCard(
            padding: const EdgeInsets.symmetric(
                horizontal: Space.l, vertical: Space.s),
            child: Column(
              children: [
                if (birth != null)
                  InfoRow(
                      icon: Icons.cake_outlined,
                      label: l10n.translate('birthDate'),
                      value: fullDateLabel(l10n, birth)),
                if (sign != null) ...[
                  const CardDivider(),
                  InfoRow(
                      icon: Icons.auto_awesome_outlined,
                      label: l10n.translate('zodiacSign'),
                      value: ZodiacContent.name(sign, l10n.locale.languageCode)),
                ],
                if (hasPhone) ...[
                  const CardDivider(),
                  InfoRow(
                      icon: Icons.phone_outlined,
                      label: l10n.translate('phone'),
                      value: contact.phone!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
