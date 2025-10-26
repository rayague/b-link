import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/profile_provider.dart';
import '../models/user_profile.dart';
import '../utils/zodiac.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  DateTime? _birthDate;
  TimeOfDay? _birthTime;
  TextEditingController _socialController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final prov = context.read<ProfileProvider>();
    final p = prov.profile;
    _nameController = TextEditingController(text: p?.name ?? '');
    _birthDate = p?.birthDate;
    if (p?.birthTime != null) {
      final parts = p!.birthTime!.split(':');
      _birthTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    _socialController.text = p?.socialLinks?.entries.first.value ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Row(children: [Image.asset('assets/logoApp.jpg', height: 28), const SizedBox(width:8), const Text('Mon profil')])),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // header image
              Image.asset('assets/pictureFirst.jpg', width: double.infinity, height: 140, fit: BoxFit.cover),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (v) => v == null || v.isEmpty ? 'Nom requis' : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(_birthDate == null ? 'Date de naissance' : _birthDate!.toLocal().toString().split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _birthDate ?? DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => _birthDate = d);
                },
              ),
              ListTile(
                title: Text(_birthTime == null ? 'Heure de naissance' : _birthTime!.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: _birthTime ?? TimeOfDay.now());
                  if (t != null) setState(() => _birthTime = t);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _socialController,
                decoration: const InputDecoration(labelText: 'Lien réseau social (ex: Instagram)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  if (_birthDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choisir la date de naissance')));
                    return;
                  }
                  final provider = context.read<ProfileProvider>();
                  final profile = UserProfile(
                    name: _nameController.text,
                    birthDate: DateTime(_birthDate!.year, _birthDate!.month, _birthDate!.day),
                    birthTime: _birthTime == null ? null : '${_birthTime!.hour.toString().padLeft(2,'0')}:${_birthTime!.minute.toString().padLeft(2,'0')}',
                    socialLinks: _socialController.text.isEmpty ? null : {'primary': _socialController.text},
                    zodiac: Zodiac.computeZodiac(_birthDate!),
                  );
                  await provider.save(profile);
                  if (!mounted) return;
                  // Use a post-frame callback to show the snackbar so we don't rely on the
                  // analyzer's build-context-after-await checks and ensure the widget is still mounted.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil sauvegardé')));
                  });
                },
                child: const Text('Sauvegarder et synchroniser'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final profile = context.read<ProfileProvider>().profile;
                  final shareText = profile == null
                      ? 'Rejoins-moi sur B Link !'
                      : 'Je suis ${profile.name}, je suis né(e) le ${profile.birthDate.toLocal().toString().split(' ')[0]}. Rejoins-moi sur B Link !';
                  await SharePlus.instance.share(ShareParams(text: shareText, subject: 'Rejoins B Link'));
                },
                child: const Text('Recommander l\'application'),
              ),
              const SizedBox(height: 20),
              if (_birthDate != null) _buildZodiacCard(_birthDate!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZodiacCard(DateTime birthDate) {
    final zodiac = _computeZodiac(birthDate);
    final desc = _zodiacDescription(zodiac);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Signe: $zodiac', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(desc),
            const SizedBox(height: 8),
            Text('Période: ' + _zodiacPeriod(zodiac)),
          ],
        ),
      ),
    );
  }

  String _zodiacDescription(String sign) {
    switch (sign) {
      case 'Bélier':
        return 'Dynamique, courageux, et impulsif.';
      case 'Taureau':
        return 'Stable, patient, et sensuel.';
      case 'Gémeaux':
        return 'Curieux, adaptable, communicatif.';
      case 'Cancer':
        return 'Émotif, protecteur, intuitif.';
      case 'Lion':
        return 'Charismatique, généreux, confiant.';
      case 'Vierge':
        return 'Analytique, méthodique, réservé.';
      case 'Balance':
        return 'Social, équilibré, juste.';
      case 'Scorpion':
        return 'Passionné, intense, mystérieux.';
      case 'Sagittaire':
        return 'Aventurier, optimiste, libre.';
      case 'Capricorne':
        return 'Ambitieux, discipliné, responsable.';
      case 'Verseau':
        return 'Original, humanitaire, indépendant.';
      case 'Poissons':
        return 'Empathique, artistique, rêveur.';
      default:
        return '';
    }
  }

  String _zodiacPeriod(String sign) {
    switch (sign) {
      case 'Bélier':
        return '21 Mar - 19 Apr';
      case 'Taureau':
        return '20 Apr - 20 May';
      case 'Gémeaux':
        return '21 May - 20 Jun';
      case 'Cancer':
        return '21 Jun - 22 Jul';
      case 'Lion':
        return '23 Jul - 22 Aug';
      case 'Vierge':
        return '23 Aug - 22 Sep';
      case 'Balance':
        return '23 Sep - 22 Oct';
      case 'Scorpion':
        return '23 Oct - 21 Nov';
      case 'Sagittaire':
        return '22 Nov - 21 Dec';
      case 'Capricorne':
        return '22 Dec - 19 Jan';
      case 'Verseau':
        return '20 Jan - 18 Feb';
      case 'Poissons':
        return '19 Feb - 20 Mar';
      default:
        return '';
    }
  }

  String _computeZodiac(DateTime birthDate) {
    final m = birthDate.month;
    final d = birthDate.day;
    if ((m == 1 && d >= 20) || (m == 2 && d <= 18)) return 'Verseau';
    if ((m == 2 && d >= 19) || (m == 3 && d <= 20)) return 'Poissons';
    if ((m == 3 && d >= 21) || (m == 4 && d <= 19)) return 'Bélier';
    if ((m == 4 && d >= 20) || (m == 5 && d <= 20)) return 'Taureau';
    if ((m == 5 && d >= 21) || (m == 6 && d <= 20)) return 'Gémeaux';
    if ((m == 6 && d >= 21) || (m == 7 && d <= 22)) return 'Cancer';
    if ((m == 7 && d >= 23) || (m == 8 && d <= 22)) return 'Lion';
    if ((m == 8 && d >= 23) || (m == 9 && d <= 22)) return 'Vierge';
    if ((m == 9 && d >= 23) || (m == 10 && d <= 22)) return 'Balance';
    if ((m == 10 && d >= 23) || (m == 11 && d <= 21)) return 'Scorpion';
    if ((m == 11 && d >= 22) || (m == 12 && d <= 21)) return 'Sagittaire';
    return 'Capricorne';
  }
}
