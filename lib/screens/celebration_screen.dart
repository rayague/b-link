import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/contact_provider.dart';
import '../models/contact.dart';
import '../utils/birthday.dart';
import '../l10n/app_localizations.dart';
import '../utils/relations.dart';
// message_generator not used here; repository is preferred
import '../services/message_repository.dart';
import '../services/analytics_service.dart';

class CelebrationScreen extends StatefulWidget {
  const CelebrationScreen({super.key});

  @override
  State<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends State<CelebrationScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView(
      screenName: 'CelebrationScreen',
      screenClass: 'CelebrationScreen',
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<ContactProvider>(context);
    final list = prov.upcoming(5);
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).translate('celebrations'))),
      body: list.isEmpty
          ? Center(child: Text(AppLocalizations.of(context).translate('noUpcomingBirthdays')))
          : ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) {
                final c = list[i];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                        child: Text(
                            c.name.isNotEmpty ? c.name[0].toUpperCase() : '?')),
                    title: Text(c.name),
                    subtitle:
                        Text('${AppLocalizations.of(context).translate('inDaysShort').replaceAll('{count}', '${_daysRemaining(c)}')} • ${relationLabel(AppLocalizations.of(context), c.relation)}'),
                    trailing: Wrap(spacing: 8, children: [
                      IconButton(
                          icon: const Icon(Icons.call, color: Colors.green),
                          onPressed: () => _call(c)),
                      IconButton(
                          icon: const Icon(Icons.message, color: Colors.blue),
                          onPressed: () => _generateAndCopy(c)),
                    ]),
                  ),
                );
              },
            ),
    );
  }

  int _daysRemaining(Contact c) {
    final d = parseBirthDate(c.date);
    return d == null ? 0 : daysUntilBirthday(d, DateTime.now());
  }

  Future<void> _call(Contact c) async {
    if (c.phone == null || c.phone!.isEmpty) return;

    // Analytics: Track call initiated
    AnalyticsService().logCallInitiated(
      relation: c.relation,
      hasPhone: true,
    );

    final uri = Uri.parse('tel:${c.phone}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _generateAndCopy(Contact c) async {
    // use DB-backed repository if available
    final repo = MessageRepository();
    final msg = await repo.getRandomForRelation(c.relation, c.name,
        lang: AppLocalizations.of(context).locale.languageCode);
    await Clipboard.setData(ClipboardData(text: msg));

    // Analytics: Track message generated
    AnalyticsService().logBirthdayMessageGenerated(
      relation: c.relation,
      messageLength: msg.length,
    );

    if (!mounted) return;

    // capture messenger in a local variable after the async gap and mounted check
    final messenger = ScaffoldMessenger.of(context);

    // Show dialog (mounted checked above)
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Generated message'),
        content: Text(msg),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Close')),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: msg));
              if (!dialogCtx.mounted) return;
              Navigator.of(dialogCtx).pop();
              messenger.showSnackBar(
                  const SnackBar(content: Text('Message copied')));
            },
            child: const Text('Copy'),
          ),
          if (c.phone != null && c.phone!.isNotEmpty)
            TextButton(
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                await _call(c);
              },
              child: const Text('Call'),
            )
        ],
      ),
    );
  }
}
