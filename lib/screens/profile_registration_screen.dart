import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../models/user_profile.dart';
import '../utils/zodiac.dart';

class ProfileRegistrationScreen extends StatefulWidget {
  const ProfileRegistrationScreen({super.key});

  @override
  State<ProfileRegistrationScreen> createState() => _ProfileRegistrationScreenState();
}

class _ProfileRegistrationScreenState extends State<ProfileRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _givenCtrl = TextEditingController();
  final _familyCtrl = TextEditingController();
  DateTime? _birthDate;
  TimeOfDay? _birthTime;
  final _birthPlaceCtrl = TextEditingController();
  final _socialCtrl = TextEditingController();
  bool _isPublic = false;
  bool _publicName = false;
  bool _publicBirthDate = false;
  bool _publicBirthPlace = false;
  bool _publicSocials = false;

  @override
  void dispose() {
    _givenCtrl.dispose();
    _familyCtrl.dispose();
    _birthPlaceCtrl.dispose();
    _socialCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create your profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(controller: _givenCtrl, decoration: const InputDecoration(labelText: 'Given name (first)'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
              const SizedBox(height: 8),
              TextFormField(controller: _familyCtrl, decoration: const InputDecoration(labelText: 'Family name (last)'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              ListTile(title: Text(_birthDate == null ? 'Birth date' : _birthDate!.toLocal().toString().split(' ')[0]), trailing: const Icon(Icons.calendar_today), onTap: () async {
                final d = await showDatePicker(context: context, initialDate: DateTime(1990,1,1), firstDate: DateTime(1900), lastDate: DateTime.now());
                if (d != null) setState(() => _birthDate = d);
              }),
              ListTile(title: Text(_birthTime == null ? 'Birth time (optional)' : _birthTime!.format(context)), trailing: const Icon(Icons.access_time), onTap: () async {
                final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: 12, minute: 0));
                if (t != null) setState(() => _birthTime = t);
              }),
              const SizedBox(height: 8),
              TextFormField(controller: _birthPlaceCtrl, decoration: const InputDecoration(labelText: 'Birth place (city, country)'), validator: (v) => null),
              const SizedBox(height: 8),
              TextFormField(controller: _socialCtrl, decoration: const InputDecoration(labelText: 'Public social link (optional)'), validator: (v) => null),
              const SizedBox(height: 12),
              SwitchListTile(title: const Text('Make my profile public'), value: _isPublic, onChanged: (v) => setState(() => _isPublic = v)),
              if (_isPublic) ...[
                CheckboxListTile(title: const Text('Show my name'), value: _publicName, onChanged: (v) => setState(() => _publicName = v ?? false)),
                CheckboxListTile(title: const Text('Show my birth date (MM-DD)'), value: _publicBirthDate, onChanged: (v) => setState(() => _publicBirthDate = v ?? false)),
                CheckboxListTile(title: const Text('Show my birth place'), value: _publicBirthPlace, onChanged: (v) => setState(() => _publicBirthPlace = v ?? false)),
                CheckboxListTile(title: const Text('Show my social links'), value: _publicSocials, onChanged: (v) => setState(() => _publicSocials = v ?? false)),
              ],
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _submit, child: const Text('Save profile'))
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please pick your birth date')));
      return;
    }
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    final displayName = '${_givenCtrl.text} ${_familyCtrl.text}';
    final profile = UserProfile(
      name: displayName,
      givenName: _givenCtrl.text,
      familyName: _familyCtrl.text,
      birthDate: DateTime(_birthDate!.year, _birthDate!.month, _birthDate!.day),
      birthTime: _birthTime == null ? null : '${_birthTime!.hour.toString().padLeft(2,'0')}:${_birthTime!.minute.toString().padLeft(2,'0')}',
      birthplace: _birthPlaceCtrl.text.isEmpty ? null : _birthPlaceCtrl.text,
      socialLinks: _socialCtrl.text.isEmpty ? null : {'primary': _socialCtrl.text},
      zodiac: Zodiac.computeZodiac(_birthDate!),
      isPublic: _isPublic,
      publicName: _publicName,
      publicBirthDate: _publicBirthDate,
      publicBirthPlace: _publicBirthPlace,
      publicSocials: _publicSocials,
    );
    await provider.save(profile, push: true);
    // After save, navigate home
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/');
  }
}
