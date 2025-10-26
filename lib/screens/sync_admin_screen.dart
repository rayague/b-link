import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../services/db_helper.dart';
import '../services/admin_service.dart';
import '../providers/auth_provider.dart' as local_auth;

enum SyncFilter { all, pending, failed, done }

class SyncAdminScreen extends StatefulWidget {
  const SyncAdminScreen({super.key});

  @override
  State<SyncAdminScreen> createState() => _SyncAdminScreenState();
}

class _SyncAdminScreenState extends State<SyncAdminScreen> {
  final DBHelper _db = DBHelper();
  List<Map<String, dynamic>> items = [];
  List<String> _actions = [];
  String _actionFilter = 'all';
  SyncFilter _filter = SyncFilter.all;
  final int _limit = 50;
  bool _loading = false;
  final AdminService _adminService = AdminService();
  String? _adminUid;
  bool _checkingAdmin = true;
  bool _retryingAll = false;
  int? _minAttempts;
  String _ageFilter = 'all'; // all, 1d,7d,30d

  @override
  void initState() {
    super.initState();
    _load();
    _loadActions();
    _loadAdmin();
  }
  Future<void> _loadActions() async {
    try {
      final db = await _db.database;
      final res = await db.rawQuery('SELECT DISTINCT action FROM sync_queue ORDER BY action');
      setState(() {
        _actions = res.map((r) => (r['action'] ?? '').toString()).where((s) => s.isNotEmpty).toList();
      });
    } catch (_) {
      // ignore
    }
  }
  Future<void> _loadAdmin() async {
    try {
      final v = await _adminService.getAdminUid();
      setState(() {
        _adminUid = v;
        _checkingAdmin = false;
      });
      // subscribe to changes
      _adminService.adminUidStream().listen((val) {
        setState(() {
          _adminUid = val;
        });
      });
    } catch (_) {
      setState(() {
        _adminUid = null;
        _checkingAdmin = false;
      });
    }
  }

  Future<void> _claimAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No authenticated user.')));
      return;
    }
    try {
      await _adminService.claimAdmin(uid);
      setState(() => _adminUid = uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin configured in Firestore.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to claim admin: $e')));
    }
  }

  Future<void> _revokeAdmin() async {
    try {
      await _adminService.revokeAdmin();
      setState(() => _adminUid = null);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin revoked.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to revoke: $e')));
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = await _db.database;
    // Build dynamic where clause based on filters: status, minAttempts and age
    final List<String> clauses = [];
    final List<Object?> args = [];
    if (_filter == SyncFilter.pending) {
      clauses.add('status = ?');
      args.add('pending');
    } else if (_filter == SyncFilter.failed) {
      clauses.add('status = ?');
      args.add('failed');
    } else if (_filter == SyncFilter.done) {
      clauses.add('status = ?');
      args.add('done');
    }
    if (_minAttempts != null) {
      clauses.add('attempts >= ?');
      args.add(_minAttempts);
    }
    if (_ageFilter != 'all') {
      DateTime cutoff = DateTime.now();
      if (_ageFilter == '1d') cutoff = cutoff.subtract(const Duration(days: 1));
      if (_ageFilter == '7d') cutoff = cutoff.subtract(const Duration(days: 7));
      if (_ageFilter == '30d') cutoff = cutoff.subtract(const Duration(days: 30));
      clauses.add('createdAt >= ?');
      args.add(cutoff.toIso8601String());
    }
    if (_actionFilter != 'all') {
      clauses.add('action = ?');
      args.add(_actionFilter);
    }
    final where = clauses.isEmpty ? null : clauses.join(' AND ');
    final whereArgs = args.isEmpty ? null : args;
    final res = await db.query('sync_queue', where: where, whereArgs: whereArgs, orderBy: 'createdAt DESC', limit: _limit);
    setState(() {
      items = res.map((r) => Map<String, dynamic>.from(r)).toList();
      _loading = false;
    });
  }

  Future<void> _requeue(int id) async {
    await _db.requeueSyncItem(id);
    await _load();
  }

  Future<void> _delete(int id) async {
    await _db.deleteSyncItem(id);
    await _load();
  }

  Future<void> _requeueAllFailed() async {
    setState(() => _retryingAll = true);
    try {
      final db = await _db.database;
      final res = await db.query('sync_queue', where: 'status = ?', whereArgs: ['failed']);
      for (final r in res) {
        final id = r['id'] as int?;
        if (id != null) await _db.requeueSyncItem(id);
      }
    } finally {
      await _load();
      setState(() => _retryingAll = false);
    }
  }

  Future<void> _exportCsv() async {
    if (items.isEmpty) return;
    final sb = StringBuffer();
    sb.writeln('id,action,status,attempts,lastError,createdAt');
    for (final it in items) {
      final id = it['id'];
      final action = (it['action'] ?? '').toString().replaceAll(',', ' ');
      final status = it['status'];
      final attempts = it['attempts'] ?? 0;
      final lastError = (it['lastError'] ?? '').toString().replaceAll(',', ' ');
      final createdAt = it['createdAt'];
      sb.writeln('$id,$action,$status,$attempts,$lastError,$createdAt');
    }
    final csv = sb.toString();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/sync_queue_${DateTime.now().toIso8601String().replaceAll(':', '-')}.csv');
      await file.writeAsString(csv);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV written to ${file.path}')));
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: csv));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exported CSV copied to clipboard')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access control: only the stored admin UID may view the admin UI.
    if (_checkingAdmin) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isAdmin = (_adminUid != null && currentUid != null && _adminUid == currentUid);

    if (_adminUid == null) {
      // No admin configured yet: show claim admin option.
      return Scaffold(
        appBar: AppBar(title: const Text('Sync Queue Admin')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('No admin user configured. The first authenticated user can claim admin rights.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  // Ensure we have an auth user before claiming
                    if (currentUid == null) {
                    final authProv = Provider.of<local_auth.AuthProvider>(context, listen: false);
                    await authProv.ensureAnonymousUser();
                  }
                  await _claimAdmin();
                },
                child: const Text('Claim admin on this device'),
              ),
            ]),
          ),
        ),
      );
    }

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sync Queue Admin')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.lock, size: 56, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Access denied. You are not the configured admin.'),
              const SizedBox(height: 8),
              Text('Configured admin UID: ${_adminUid ?? 'unknown'}', style: const TextStyle(fontSize: 12))
            ]),
          ),
        ),
      );
    }

    // Admin is confirmed — show admin UI
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Queue Admin'),
        actions: [
          IconButton(onPressed: () => _load(), icon: const Icon(Icons.refresh), tooltip: 'Reload'),
          IconButton(onPressed: () => _revokeAdmin(), icon: const Icon(Icons.person_off), tooltip: 'Revoke admin'),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            label: _retryingAll ? const Text('Retrying...') : const Text('Retry failed'),
            icon: _retryingAll ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.refresh),
            onPressed: _retryingAll ? null : () async => await _requeueAllFailed(),
            tooltip: 'Requeue all failed items',
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            label: const Text('Export'),
            icon: const Icon(Icons.download),
            onPressed: () async => await _exportCsv(),
            tooltip: 'Copy CSV to clipboard',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Text('Filter:'),
                const SizedBox(width: 8),
                DropdownButton<SyncFilter>(
                  value: _filter,
                  items: const [
                    DropdownMenuItem(value: SyncFilter.all, child: Text('All')),
                    DropdownMenuItem(value: SyncFilter.pending, child: Text('Pending')),
                    DropdownMenuItem(value: SyncFilter.failed, child: Text('Failed')),
                    DropdownMenuItem(value: SyncFilter.done, child: Text('Done')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _filter = v);
                    _load();
                  },
                ),
                const SizedBox(width: 12),
                // min attempts
                SizedBox(
                  width: 120,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Min attempts', isDense: true),
                    onSubmitted: (s) {
                      final v = int.tryParse(s);
                      setState(() => _minAttempts = v);
                      _load();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _ageFilter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Any age')),
                    DropdownMenuItem(value: '1d', child: Text('<1 day')),
                    DropdownMenuItem(value: '7d', child: Text('<7 days')),
                    DropdownMenuItem(value: '30d', child: Text('<30 days')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _ageFilter = v);
                    _load();
                  },
                ),
                const SizedBox(width: 12),
                // action filter (populated from DB distinct actions)
                DropdownButton<String>(
                  value: _actionFilter,
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('All actions')),
                    ..._actions.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _actionFilter = v);
                    _load();
                  },
                ),
                const Spacer(),
                if (_loading) const CircularProgressIndicator(),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final it = items[i];
                return ListTile(
                  onTap: () => _showDetails(it['id'] as int, it),
                  title: Text('${it['action']} (${it['status']})'),
                  subtitle: Text('id:${it['id']} attempts:${it['attempts'] ?? 0}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () async => await _requeue(it['id'] as int),
                        tooltip: 'Requeue',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async => await _delete(it['id'] as int),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDetails(int id, Map<String, dynamic> it) async {
    final payloadRaw = it['payload'];
    String pretty = '';
    try {
      if (payloadRaw == null) {
        pretty = '<no payload>';
      } else if (payloadRaw is String) {
        final decoded = json.decode(payloadRaw);
        pretty = const JsonEncoder.withIndent('  ').convert(decoded);
      } else {
        pretty = const JsonEncoder.withIndent('  ').convert(payloadRaw);
      }
    } catch (e) {
      pretty = payloadRaw?.toString() ?? '<unrenderable>';
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Item $id — ${it['action']}'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(pretty),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () async {
                try {
                  await Clipboard.setData(ClipboardData(text: pretty));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payload copied')));
                } catch (_) {
                  // ignore
                }
              },
              child: const Text('Copy')),
          TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _requeue(id);
              },
              child: const Text('Retry')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
        ],
      ),
    );
  }
}
