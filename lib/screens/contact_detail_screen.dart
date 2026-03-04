import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../models/contact.dart';
import '../providers/contact_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
import '../services/analytics_service.dart';

class ContactDetailScreen extends StatefulWidget {
  const ContactDetailScreen({super.key});

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _date = TextEditingController();
  final _relation = TextEditingController();
  final _phone = TextEditingController();
  String? _imagePath;
  String? _selectedRelation;
  final relations = [
    'SON',
    'DAUGHTER',
    'SISTER',
    'BROTHER',
    'FRIEND',
    'NEIGHBOR',
    'BESTFRIEND',
    'BOYFRIEND',
    'GIRLFRIEND',
    'HUSBAND',
    'FATHER',
    'MOTHER',
    'AUNTIE',
    'UNCLE',
    'COUSIN',
    'NIECE',
    'NEPHEW',
    'GRAND-SON',
    'GRAND-DAUGHTER',
    'GRAND-FATHER',
    'GRAND-MOTHER',
    'GOD-FATHER',
    'GOD-MOTHER'
  ];
  Contact? _contact;
  bool _isEditing = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    AnalyticsService().logScreenView(
      screenName: 'ContactDetailScreen',
      screenClass: 'ContactDetailScreen',
    );

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)!.settings.arguments;
    if (arg is Contact) {
      _contact = arg;
      _name.text = _contact!.name;
      _date.text = _contact!.date;
      _relation.text = _contact!.relation;
      _selectedRelation = _contact!.relation;
      _phone.text = _contact!.phone ?? '';
      _imagePath = _contact!.imageUri;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _date.dispose();
    _relation.dispose();
    _phone.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _updateContact() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Veuillez choisir une date de naissance'),
            ],
          ),
          backgroundColor: Colors.red[400],
        ),
      );
      return;
    }

    final updated = Contact(
      id: _contact!.id,
      name: _name.text.trim(),
      date: _date.text.trim(),
      relation: _selectedRelation ?? _relation.text.trim(),
      imageUri: _imagePath,
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
    );

    final locale = Provider.of<LocaleProvider>(context, listen: false);
    await Provider.of<ContactProvider>(context, listen: false)
        .updateContact(updated, locale: locale.locale.languageCode);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).translate('contactUpdated')),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_contact == null) {
      return const Scaffold(body: Center(child: Text('No contact')));
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1F2937), const Color(0xFF111827)]
                : [const Color(0xFFF9FAFB), Colors.white],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Custom App Bar
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFF3B82F6), const Color(0xFF2563EB)]
                          : [
                              const Color(0xFF3B82F6),
                              const Color(0xFF60A5FA),
                              const Color(0xFF93C5FD)
                            ],
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Decorative circles
                      Positioned(
                        right: -50,
                        top: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -30,
                        bottom: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      FlexibleSpaceBar(
                        titlePadding:
                            const EdgeInsets.only(left: 60, bottom: 16),
                        title: Text(
                          _contact!.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        background: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),
                              GestureDetector(
                                onTap: _isEditing
                                    ? () async {
                                        final img =
                                            await ImagePicker().pickImage(
                                          source: ImageSource.gallery,
                                          imageQuality: 80,
                                        );
                                        if (img != null) {
                                          setState(() => _imagePath = img.path);
                                        }
                                      }
                                    : null,
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 90,
                                      height: 90,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: _imagePath != null &&
                                                File(_imagePath!).existsSync()
                                            ? DecorationImage(
                                                image: FileImage(
                                                    File(_imagePath!)),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                        gradient: _imagePath == null
                                            ? const LinearGradient(
                                                colors: [
                                                  Colors.white,
                                                  Color(0xFFDDE5FF)
                                                ],
                                              )
                                            : null,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withValues(alpha: 0.2),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: _imagePath == null
                                          ? Center(
                                              child: Text(
                                                _contact!.name.isNotEmpty
                                                    ? _contact!.name[0]
                                                        .toUpperCase()
                                                    : '?',
                                                style: const TextStyle(
                                                  fontSize: 40,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF3B82F6),
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                    if (_isEditing)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF3B82F6),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      _isEditing ? Icons.close : Icons.edit,
                      color: Colors.white,
                    ),
                    onPressed: () => setState(() => _isEditing = !_isEditing),
                  ),
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Info Card
                          _buildInfoCard(isDark),
                          const SizedBox(height: 20),

                          // Actions
                          if (_isEditing) _buildSaveButton(isDark),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF374151) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Informations du contact',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Name Field
          _buildModernTextField(
            controller: _name,
            label: AppLocalizations.of(context).translate('fullName'),
            hint: 'Ex: Marie Dupont',
            icon: Icons.badge_outlined,
            isDark: isDark,
            enabled: _isEditing,
            validator: (v) => v == null || v.isEmpty ? 'Nom requis' : null,
          ),
          const SizedBox(height: 16),

          // Birth Date
          _buildDateSelector(isDark),
          const SizedBox(height: 16),

          // Relation
          _buildRelationSelector(isDark),
          const SizedBox(height: 16),

          // Phone
          _buildModernTextField(
            controller: _phone,
            label: AppLocalizations.of(context).translate('phone'),
            hint: 'Ex: +33 6 12 34 56 78',
            icon: Icons.phone_outlined,
            isDark: isDark,
            enabled: _isEditing,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[300] : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          validator: validator,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            prefixIcon: Icon(
              icon,
              color: enabled
                  ? (isDark ? Colors.grey[400] : const Color(0xFF6B7280))
                  : Colors.grey[600],
            ),
            filled: true,
            fillColor: enabled
                ? (isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB))
                : (isDark ? const Color(0xFF111827) : Colors.grey[100]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF3B82F6),
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date de naissance',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[300] : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _isEditing
              ? () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: now,
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF3B82F6),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() =>
                        _date.text = picked.toIso8601String().split('T').first);
                  }
                }
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: _isEditing
                  ? (isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB))
                  : (isDark ? const Color(0xFF111827) : Colors.grey[100]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cake_outlined,
                  color: _isEditing
                      ? (isDark ? Colors.grey[400] : const Color(0xFF6B7280))
                      : Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Text(
                  _date.text.isEmpty
                      ? AppLocalizations.of(context).translate('selectDate')
                      : _date.text,
                  style: TextStyle(
                    fontSize: 16,
                    color: _date.text.isEmpty
                        ? (isDark ? Colors.grey[600] : Colors.grey[400])
                        : (isDark ? Colors.white : const Color(0xFF1F2937)),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRelationSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Relation',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[300] : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _isEditing
                ? (isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB))
                : (isDark ? const Color(0xFF111827) : Colors.grey[100]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
            ),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedRelation,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.people_outline,
                color: _isEditing
                    ? (isDark ? Colors.grey[400] : const Color(0xFF6B7280))
                    : Colors.grey[600],
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            hint: Text(
              AppLocalizations.of(context).translate('selectRelation'),
              style: TextStyle(
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ),
            items: relations
                .map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(r),
                    ))
                .toList(),
            onChanged: _isEditing
                ? (v) {
                    setState(() {
                      _selectedRelation = v;
                      _relation.text = v ?? '';
                    });
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _updateContact,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.save_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).translate('update'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
