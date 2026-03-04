import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/contact.dart';
import '../providers/contact_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
import 'dart:math' as math;
import '../services/analytics_service.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    AnalyticsService().logScreenView(
      screenName: 'ListScreen',
      screenClass: 'ListScreen',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = Provider.of<ContactProvider>(context, listen: false);
      final locale = Provider.of<LocaleProvider>(context, listen: false);
      prov.loadContacts(locale: locale.locale.languageCode);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAdd(BuildContext ctx) {
    final nameCtl = TextEditingController();
    final dateCtl = TextEditingController();
    final relationCtl = TextEditingController();
    final phoneCtl = TextEditingController();
    String? imagePath;
    String? selectedRelation;
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

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                    ),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.person_add_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(dialogCtx).translate('addContact'),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(dialogCtx),
                      ),
                    ],
                  ),
                ),

                // Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Photo picker
                        Center(
                          child: GestureDetector(
                            onTap: () async {
                              final img = await ImagePicker().pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 80,
                              );
                              if (img != null) {
                                setDialogState(() => imagePath = img.path);
                              }
                            },
                            child: Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: imagePath == null
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFF8B5CF6),
                                              Color(0xFFA78BFA)
                                            ],
                                          )
                                        : null,
                                    image: imagePath != null
                                        ? DecorationImage(
                                            image: FileImage(File(imagePath!)),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: imagePath == null
                                      ? const Icon(Icons.person,
                                          size: 50, color: Colors.white)
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.camera_alt,
                                        size: 16, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Name
                        _buildModernTextField(
                          controller: nameCtl,
                          label: AppLocalizations.of(dialogCtx)
                              .translate('fullName'),
                          hint: 'Ex: Jean Dupont',
                          icon: Icons.person_outline,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),

                        // Date
                        _buildModernTextField(
                          controller: dateCtl,
                          label: AppLocalizations.of(dialogCtx)
                              .translate('birthDate'),
                          hint: AppLocalizations.of(dialogCtx)
                              .translate('selectDate'),
                          icon: Icons.cake_outlined,
                          isDark: isDark,
                          readOnly: true,
                          onTap: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: dialogCtx,
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
                              setDialogState(() => dateCtl.text =
                                  picked.toIso8601String().split('T').first);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Relation
                        Text(
                          AppLocalizations.of(dialogCtx).translate('relation'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.grey[300]
                                : const Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF374151)
                                : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF4B5563)
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedRelation,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.people_outline,
                                color: isDark
                                    ? Colors.grey[400]
                                    : const Color(0xFF6B7280),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                            ),
                            hint: Text(
                              AppLocalizations.of(dialogCtx)
                                  .translate('selectRelation'),
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[600]
                                    : Colors.grey[400],
                              ),
                            ),
                            items: relations
                                .map((r) => DropdownMenuItem(
                                      value: r,
                                      child: Text(r),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              setDialogState(() {
                                selectedRelation = v;
                                relationCtl.text = v ?? '';
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Phone (optional)
                        _buildModernTextField(
                          controller: phoneCtl,
                          label:
                              AppLocalizations.of(dialogCtx).translate('phone'),
                          hint: 'Ex: +33 6 12 34 56 78',
                          icon: Icons.phone_outlined,
                          isDark: isDark,
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom buttons
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF111827) : Colors.grey[50],
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? const Color(0xFF374151)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Color(0xFF3B82F6)),
                          ),
                          child: Text(
                            AppLocalizations.of(dialogCtx).translate('cancel'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              final name = nameCtl.text.trim();
                              final date = dateCtl.text.trim();
                              final relation = relationCtl.text.trim();

                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          AppLocalizations.of(dialogCtx)
                                              .translate('enterName'))),
                                );
                                return;
                              }

                              if (date.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          AppLocalizations.of(dialogCtx)
                                              .translate('selectBirthDate'))),
                                );
                                return;
                              }

                              final c = Contact(
                                name: name,
                                date: date,
                                relation:
                                    relation.isEmpty ? 'FRIEND' : relation,
                                phone: phoneCtl.text.trim().isEmpty
                                    ? null
                                    : phoneCtl.text.trim(),
                                imageUri: imagePath,
                              );

                              final locale = Provider.of<LocaleProvider>(
                                  context,
                                  listen: false);
                              await Provider.of<ContactProvider>(context,
                                      listen: false)
                                  .addContact(c,
                                      locale: locale.locale.languageCode);
                              if (!mounted) return;
                              Navigator.of(context).pop();

                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '✅ ${AppLocalizations.of(dialogCtx).translate('contactAdded').replaceAll('{name}', name)}'),
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_outline,
                                    size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(dialogCtx)
                                      .translate('save'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
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
        TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
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
              color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
            ),
            filled: true,
            fillColor:
                isDark ? const Color(0xFF374151) : const Color(0xFFF9FAFB),
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<ContactProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter contacts based on search
    final filteredContacts = prov.contacts.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.relation.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

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
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context).translate('myContacts'),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${prov.contacts.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF374151) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)
                              .translate('searchContact'),
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: isDark
                                ? Colors.grey[400]
                                : const Color(0xFF6B7280),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: prov.loading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredContacts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _searchQuery.isEmpty
                                      ? Icons.people_outline
                                      : Icons.search_off,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? AppLocalizations.of(context)
                                          .translate('noContact')
                                      : AppLocalizations.of(context)
                                          .translate('noResults'),
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchQuery.isEmpty
                                      ? AppLocalizations.of(context)
                                          .translate('pressToAdd')
                                      : AppLocalizations.of(context)
                                          .translate('tryAnotherSearch'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: filteredContacts.length,
                            itemBuilder: (_, i) {
                              final c = filteredContacts[i];
                              final bday = DateTime.tryParse(c.date);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF374151)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  leading: c.imageUri != null &&
                                          File(c.imageUri!).existsSync()
                                      ? CircleAvatar(
                                          radius: 28,
                                          backgroundImage:
                                              FileImage(File(c.imageUri!)),
                                        )
                                      : Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [
                                                Color((math.Random(c.name
                                                                    .hashCode)
                                                                .nextDouble() *
                                                            0xFFFFFF)
                                                        .toInt())
                                                    .withValues(alpha: 1.0),
                                                Color((math.Random(c.name
                                                                        .hashCode +
                                                                    1)
                                                                .nextDouble() *
                                                            0xFFFFFF)
                                                        .toInt())
                                                    .withValues(alpha: 1.0),
                                              ],
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              c.name.isNotEmpty
                                                  ? c.name[0].toUpperCase()
                                                  : '?',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                  title: Text(
                                    c.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.favorite_border,
                                        size: 14,
                                        color: isDark
                                            ? Colors.grey[500]
                                            : Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          c.relation,
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (bday != null) ...[
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.cake,
                                          size: 14,
                                          color: isDark
                                              ? Colors.grey[500]
                                              : Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${bday.day}/${bday.month}',
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  trailing: SizedBox(
                                    width: 80,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete_outline,
                                            color: Colors.red[400],
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () async {
                                            final confirm =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: Text(
                                                    AppLocalizations.of(context)
                                                        .translate('confirm')),
                                                content: Text(
                                                    '${AppLocalizations.of(context).translate('delete')} ${c.name}?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            ctx, false),
                                                    child: Text(AppLocalizations
                                                            .of(context)
                                                        .translate('cancel')),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            ctx, true),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                    child: Text(AppLocalizations
                                                            .of(context)
                                                        .translate('delete')),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirm == true &&
                                                c.id != null) {
                                              await prov.deleteContact(c.id!);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        '${c.name} ${AppLocalizations.of(context).translate("contactDeleted")}'),
                                                    backgroundColor:
                                                        Colors.red[400],
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                        const Icon(Icons.chevron_right,
                                            size: 20),
                                      ],
                                    ),
                                  ),
                                  onTap: () => Navigator.of(context)
                                      .pushNamed('/detail', arguments: c),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAdd(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(AppLocalizations.of(context).translate('add')),
        backgroundColor: const Color(0xFF3B82F6),
        elevation: 4,
      ),
    );
  }
}
