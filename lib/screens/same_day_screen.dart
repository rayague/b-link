import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/db_helper.dart';
import '../providers/profile_provider.dart';

class SameDayScreen extends StatefulWidget {
  const SameDayScreen({super.key});

  @override
  State<SameDayScreen> createState() => _SameDayScreenState();
}

class _SameDayScreenState extends State<SameDayScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; });
    final prov = Provider.of<ProfileProvider>(context, listen: false);
    final profile = prov.profile;
    if (profile == null) {
      setState(() { _loading = false; });
      return;
    }
    final key = '${profile.birthDate.month.toString().padLeft(2,'0')}-${profile.birthDate.day.toString().padLeft(2,'0')}';
    // Try Firestore first for global count
    try {
      final fs = FirebaseFirestore.instance;
      final q = await fs.collection('profiles').where('birthDayKey', isEqualTo: key).where('isPublic', isEqualTo: true).limit(200).get();
      final docs = q.docs.map((d) => d.data()).toList();
      setState(() { _items = docs.map((d) => Map<String, dynamic>.from(d)).toList(); _count = q.size; _loading = false; });
      return;
    } catch (_) {}

    // Fallback to local DB
    try {
      final db = DBHelper();
      final local = await db.queryPublicProfilesByDay(key, limit: 200);
      setState(() { _items = local; _count = local.length; _loading = false; });
    } catch (_) {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('People born the same day')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('There are $_count public profiles who share your birthday', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Expanded(child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final it = _items[i];
                final name = it['publicName'] == 1 || it['publicName'] == true ? (it['name'] ?? 'Anonymous') : 'Anonymous';
                final place = (it['publicBirthPlace'] == 1 || it['publicBirthPlace'] == true) ? (it['birthplace'] ?? '') : '';
                final socials = (it['publicSocials'] == 1 || it['publicSocials'] == true) ? (it['socialLinks'] ?? {}) : {};
                return ListTile(
                  title: Text(name),
                  subtitle: Text(place),
                  trailing: socials is Map && socials.isNotEmpty ? const Icon(Icons.link) : null,
                );
              },
            ))
          ],
        ),
      ),
    );
  }
}
