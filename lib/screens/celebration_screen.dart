import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/contact_provider.dart';
import '../models/contact.dart';
// message_generator not used here; repository is preferred
import '../services/message_repository.dart';

class CelebrationScreen extends StatefulWidget {
  const CelebrationScreen({super.key});

  @override
  State<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends State<CelebrationScreen> {
  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<ContactProvider>(context);
    final list = prov.upcoming(5);
    return Scaffold(
      appBar: AppBar(title: const Text('Celebrations')),
      body: list.isEmpty
          ? const Center(child: Text('No upcoming birthdays'))
          : ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) {
                final c = list[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?')),
                    title: Text(c.name),
                    subtitle: Text('In ${_daysRemaining(c)} days • ${c.relation}'),
                    trailing: Wrap(spacing: 8, children: [
                      IconButton(icon: const Icon(Icons.call, color: Colors.green), onPressed: () => _call(c)),
                      IconButton(icon: const Icon(Icons.message, color: Colors.blue), onPressed: () => _generateAndCopy(c)),
                    ]),
                  ),
                );
              },
            ),
    );
  }

  int _daysRemaining(Contact c) {
    try {
      final now = DateTime.now();
      final d = DateTime.parse(c.date);
      final next = DateTime(now.year, d.month, d.day);
      return next.difference(now).inDays;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _call(Contact c) async {
    if (c.phone == null || c.phone!.isEmpty) return;
    final uri = Uri.parse('tel:${c.phone}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _generateAndCopy(Contact c) async {
    // use DB-backed repository if available
    final repo = MessageRepository();
    final msg = await repo.getRandomForRelation(c.relation, c.name);
    await Clipboard.setData(ClipboardData(text: msg));

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
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('Close')),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: msg));
              Navigator.of(dialogCtx).pop();
              messenger.showSnackBar(const SnackBar(content: Text('Message copied')));
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
