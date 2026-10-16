import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/profile_provider.dart';
import '../models/user_profile.dart';
import 'public_profile_screen.dart';
import 'meetups_screen.dart';
import 'dart:math' as math;
import '../services/message_repository.dart';
import '../l10n/app_localizations.dart';
import '../widgets/greeting_card.dart';
import '../utils/relations.dart';
import 'package:flutter/services.dart';
import '../services/analytics_service.dart';
import '../services/safety_service.dart';
import '../widgets/profile_avatar.dart';
import '../services/directory_service.dart';
import '../utils/city.dart';
import '../utils/app_links.dart';
import 'package:country_picker/country_picker.dart';
import 'package:share_plus/share_plus.dart';

class SameDayScreen extends StatefulWidget {
  const SameDayScreen({super.key});

  @override
  State<SameDayScreen> createState() => _SameDayScreenState();
}

class _SameDayScreenState extends State<SameDayScreen>
    with SingleTickerProviderStateMixin {
  late AppLocalizations l10n;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  int _count = 0;
  bool _hasMore = true;
  final int _limit = DirectoryService.pageSize;
  DirectoryPeriod _period = DirectoryPeriod.day;
  _Scope _scope = _Scope.world;
  DocumentSnapshot? _lastDocument;
  Set<String> _blocked = {};
  final ScrollController _scrollController = ScrollController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    AnalyticsService().logScreenView(
      screenName: 'SameDayScreen',
      screenClass: 'SameDayScreen',
    );

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      _loadMore();
    }
  }

  // Helper pour conversion booléenne
  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    return false;
  }

  // Helper pour couleur pseudo-aléatoire
  Color _getColorForName(String name, int index) {
    final hash = name.hashCode + index;
    final random = math.Random(hash);
    return Color(0xFF000000 + (random.nextInt(0xFFFFFF)));
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
    });

    if (!mounted) return;
    final prov = Provider.of<ProfileProvider>(context, listen: false);
    final profile = prov.profile;

    if (!mounted) return;
    if (profile == null) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      return;
    }

    try {
      _blocked = await SafetyService().blockedUids();
      final q = await _query(profile).get();
      if (mounted) {
        setState(() {
          _items = _withoutMe(q.docs);
          _count = _items.length;
          _loading = false;
          _hasMore = q.size == _limit;
          _lastDocument = q.docs.isNotEmpty ? q.docs.last : null;
        });
      }
    } catch (e) {
      debugPrint('Erreur Firestore: $e');
      if (mounted) setState(() => _loading = false);
    }
    _animationController.forward();
  }

  /// Annuaire public : seule collection lisible par les autres utilisateurs.
  /// Les règles Firestore imposent une limite <= 50 par requête.
  Query<Map<String, dynamic>> _query(UserProfile me) =>
      DirectoryService().query(
        me.birthDate,
        _period,
        countryCode: _scope == _Scope.country ? me.countryCode : null,
        cityKey: _scope == _Scope.city ? cityKey(me.countryCode, me.birthCity) : null,
      );

  void _setFilters({DirectoryPeriod? period, _Scope? scope}) {
    setState(() {
      _period = period ?? _period;
      _scope = scope ?? _scope;
      _items = [];
      _lastDocument = null;
      _hasMore = true;
    });
    _load();
  }

  /// Invite des proches nés à la même date : le seul moyen de remplir
  /// l'annuaire au lancement.
  Future<void> _invite(UserProfile me) async {
    final date = '${me.birthDate.day.toString().padLeft(2, '0')}/'
        '${me.birthDate.month.toString().padLeft(2, '0')}';
    await SharePlus.instance.share(ShareParams(
      text: l10n
          .translate('inviteText')
          .replaceAll('{date}', date)
          .replaceAll('{link}', AppLinks.invite),
    ));
  }

  /// On ne se compte pas soi-même, ni les profils bloqués.
  List<Map<String, dynamic>> _withoutMe(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    return docs
        .where((d) => d.id != myUid && !_blocked.contains(d.id))
        .map((d) => d.data())
        .toList();
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loading) return;

    if (!mounted) return;
    setState(() => _loading = true);

    final prov = Provider.of<ProfileProvider>(context, listen: false);
    final profile = prov.profile;
    if (profile == null || _lastDocument == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    try {
      final q = await _query(profile)
          .startAfterDocument(_lastDocument!)
          .get();

      if (mounted && q.docs.isNotEmpty) {
        setState(() {
          _items.addAll(_withoutMe(q.docs));
          _count = _items.length;
          _hasMore = q.size == _limit;
          _lastDocument = q.docs.last;
          _loading = false;
        });
      } else if (mounted) {
        setState(() {
          _loading = false;
          _hasMore = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur pagination: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _hasMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    l10n = AppLocalizations.of(context);
    final profile = Provider.of<ProfileProvider>(context).profile;

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
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Custom App Bar
              SliverAppBar(
                expandedHeight: 180,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFFEC4899), const Color(0xFFF472B6)]
                          : [
                              const Color(0xFFEC4899),
                              const Color(0xFFF472B6),
                              const Color(0xFFFBBF24)
                            ],
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Decorative circles
                      Positioned(
                        right: -40,
                        top: -40,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -20,
                        bottom: -20,
                        child: Container(
                          width: 120,
                          height: 120,
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
                          l10n.translate('sameDay'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        background: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 30),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  profile != null
                                      ? '${profile.birthDate.day}/${profile.birthDate.month}'
                                      : '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark
                                  ? [
                                      const Color(0xFF374151),
                                      const Color(0xFF1F2937)
                                    ]
                                  : [
                                      const Color(0xFFFFF7ED),
                                      const Color(0xFFFED7AA)
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFEC4899),
                                      Color(0xFFF472B6)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.group,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$_count${_hasMore ? '+' : ''} ${l10n.translate('peopleCount')}',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1F2937),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.translate('shareYourBirthday'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Filtres : période et pays
                        _buildFilters(profile),
                        const SizedBox(height: 24),

                        // List Header
                        if (_items.isNotEmpty) ...[
                          Text(
                            l10n.translate('publicProfiles'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // List
              if (_loading && _items.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_items.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.translate('noProfileFound'),
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.translate('beTheFirst'),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        if (profile != null) ...[
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () => _invite(profile),
                            icon: const Icon(Icons.share),
                            label: Text(l10n.translate('inviteFriends')),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final it = _items[i];
                        final name = _toBool(it['publicName'])
                            ? (it['name'] ?? 'Anonymous')
                            : 'Anonymous';
                        final place = _toBool(it['publicBirthPlace'])
                            ? (it['birthplace'] ?? '')
                            : '';
                        final socials = _toBool(it['publicSocials'])
                            ? (it['socialLinks'] ?? {})
                            : {};

                        return Container(
                          key: ValueKey(it['uid'] ?? i),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color:
                                isDark ? const Color(0xFF374151) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                onTap: () =>
                                    _showProfileDetails(context, it, isDark),
                                leading: ProfileAvatar(
                                  uid: it['uid'] as String?,
                                  name: name,
                                  size: 56,
                                  // Ne tente de charger que les photos partagées.
                                  showPhoto: it['publicPhoto'] == true,
                                  gradient: [
                                    _getColorForName(name, 0),
                                    _getColorForName(name, 1),
                                  ],
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: place.isNotEmpty
                                    ? Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            size: 14,
                                            color: isDark
                                                ? Colors.grey[500]
                                                : Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              place,
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.grey[400]
                                                    : Colors.grey[600],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      )
                                    : null,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (socials is Map && socials.isNotEmpty)
                                      Icon(
                                        Icons.link,
                                        color: isDark
                                            ? Colors.grey[500]
                                            : const Color(0xFF6B7280),
                                        size: 20,
                                      ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: isDark
                                          ? Colors.grey[600]
                                          : const Color(0xFF9CA3AF),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 16, right: 16, bottom: 12),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final repo = MessageRepository();
                                      final relation =
                                          it['relation'] ?? 'default';
                                      final displayName = name;
                                      final msg =
                                          await repo.getRandomForRelation(
                                              relation, displayName,
                                              lang: l10n.locale.languageCode);
                                      if (!context.mounted) return;
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor:
                                              const Color(0xFF1D1E33),
                                          title: Row(
                                            children: [
                                              const Text('🎂',
                                                  style:
                                                      TextStyle(fontSize: 28)),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  '${l10n.translate('messageFor')} $displayName',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          content: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxHeight: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.6,
                                            ),
                                            child: SingleChildScrollView(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                              0xFFEC4899)
                                                          .withValues(alpha: 0.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Text(
                                                      '${l10n.translate('category')}: ${relationLabel(l10n, relation)}',
                                                      style: const TextStyle(
                                                        color:
                                                            Color(0xFFEC4899),
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            16),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFF0A0E21),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      border: Border.all(
                                                          color: const Color(
                                                              0xFF3A3E5B)),
                                                    ),
                                                    child: SelectableText(
                                                      msg,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                        height: 1.6,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    l10n.translate('copyHelp'),
                                                    style: const TextStyle(
                                                      color: Colors.white54,
                                                      fontSize: 11,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          actions: [
                                            TextButton.icon(
                                              onPressed: () async {
                                                await Clipboard.setData(
                                                    ClipboardData(text: msg));
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Row(
                                                        children: [
                                                          const Icon(
                                                              Icons
                                                                  .check_circle,
                                                              color:
                                                                  Colors.white),
                                                          const SizedBox(
                                                              width: 12),
                                                          Expanded(
                                                            child: Text(
                                                              l10n.translate(
                                                                  'messageCopied'),
                                                              style:
                                                                  const TextStyle(
                                                                      fontSize:
                                                                          13),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      backgroundColor:
                                                          Colors.green,
                                                      duration: const Duration(
                                                          seconds: 3),
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                    ),
                                                  );
                                                  Navigator.pop(context);
                                                }
                                              },
                                              icon: const Icon(Icons.copy_all,
                                                  color: Color(0xFFEC4899)),
                                              label: Text(
                                                AppLocalizations.of(context).translate('copyMessage'),
                                                style: const TextStyle(
                                                    color: Color(0xFFEC4899),
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            TextButton.icon(
                                              onPressed: () =>
                                                  showGreetingCardDialog(
                                                      context,
                                                      name: displayName,
                                                      message: msg,
                                                      relation: relation),
                                              icon: const Icon(
                                                  Icons.image_outlined,
                                                  color: Color(0xFFFBBF24)),
                                              label: Text(
                                                l10n.translate('makeCard'),
                                                style: const TextStyle(
                                                    color: Color(0xFFFBBF24)),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: Text(
                                                AppLocalizations.of(context).translate('close'),
                                                style: const TextStyle(
                                                    color: Colors.white70),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.card_giftcard,
                                        size: 16),
                                    label: Text(
                                        l10n.translate('generateMessage'),
                                        style: const TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFEC4899),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      minimumSize: const Size(0, 32),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: _items.length,
                    ),
                  ),
                ),

              // Indicateur de chargement pour la pagination
              if (_loading && _items.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),

              // Padding final
              const SliverPadding(
                padding: EdgeInsets.only(bottom: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(UserProfile? me) {
    final hasCountry = UserProfile.isValidCountryCode(me?.countryCode);
    final hasCity = cityKey(me?.countryCode, me?.birthCity) != null;
    final flag = hasCountry ? Country.tryParse(me!.countryCode!)?.flagEmoji ?? '' : '';
    Widget scopeChip(_Scope scope, String label, bool enabled) => ChoiceChip(
          label: Text(label),
          selected: _scope == scope,
          // Sans pays (ou ville) dans le profil, le filtre n'a pas de sens.
          onSelected: enabled ? (_) => _setFilters(scope: scope) : null,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<DirectoryPeriod>(
          segments: [
            ButtonSegment(
                value: DirectoryPeriod.day,
                label: Text(l10n.translate('periodDay'))),
            ButtonSegment(
                value: DirectoryPeriod.week,
                label: Text(l10n.translate('periodWeek'))),
            ButtonSegment(
                value: DirectoryPeriod.month,
                label: Text(l10n.translate('periodMonth'))),
          ],
          selected: {_period},
          onSelectionChanged: (s) => _setFilters(period: s.first),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            scopeChip(_Scope.world, '🌍 ${l10n.translate('scopeWorld')}', true),
            scopeChip(_Scope.country,
                '${flag.isEmpty ? '🏳️' : flag} ${l10n.translate('myCountry')}', hasCountry),
            scopeChip(_Scope.city, '🏙️ ${l10n.translate('myCity')}', hasCity),
          ],
        ),
        Row(
          children: [
            TextButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed(MeetupsScreen.routeName),
              icon: const Icon(Icons.celebration_outlined, size: 18),
              label: Text(l10n.translate('meetupsButton')),
            ),
            const Spacer(),
            if (me != null)
              TextButton.icon(
                onPressed: () => _invite(me),
                icon: const Icon(Icons.share, size: 18),
                label: Text(l10n.translate('inviteFriends')),
              ),
          ],
        ),
        if (!hasCountry || !hasCity)
          Text(
            l10n.translate(hasCountry ? 'setCityHint' : 'setCountryHint'),
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
      ],
    );
  }

  Future<void> _showProfileDetails(
      BuildContext context, Map<String, dynamic> profileData, bool isDark) async {
    // Convert Map to UserProfile
    final profile = UserProfile.fromMap(profileData);

    final blocked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(profile: profile),
      ),
    );
    if (blocked == true && mounted) {
      setState(() {
        _blocked.add(profile.uid!);
        _items.removeWhere((it) => it['uid'] == profile.uid);
        _count = _items.length;
      });
    }
  }
}

/// Portée de l'annuaire : monde entier, mon pays, ma ville.
enum _Scope { world, country, city }
