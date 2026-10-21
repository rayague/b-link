import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'glass.dart';

/// Nom du pays dans la langue de l'app (repli : nom anglais).
String countryLabel(BuildContext context, Country country) =>
    CountryLocalizations.of(context)
        ?.countryName(countryCode: country.countryCode) ??
    country.name;

/// Choix d'un pays : feuille opaque avec recherche (sans accents ni
/// majuscules), pays triés dans la langue de l'app, drapeau et coche.
///
/// Remplace la feuille de `country_picker`, transparente avec notre thème :
/// la liste se mélangeait au formulaire du dessous.
Future<Country?> showCountrySheet(BuildContext context, {String? selected}) =>
    showGlassSheet<Country>(
      context,
      expand: true,
      builder: (_) => _CountrySheet(selected: selected),
    );

class _CountrySheet extends StatefulWidget {
  final String? selected;
  const _CountrySheet({this.selected});

  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  final _search = TextEditingController();
  List<(Country, String, String)>? _all; // pays, nom affiché, clé de recherche
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _all ??= [
      for (final c in CountryService().getAll())
        (c, countryLabel(context, c), _fold(countryLabel(context, c))),
    ]..sort((a, b) => a.$3.compareTo(b.$3));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// « Bénin » et « benin » se trouvent l'un l'autre.
  static String _fold(String s) {
    const from = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿœæ';
    const to = 'aaaaaaceeeeiiiinooooouuuuyyoa';
    final lower = s.toLowerCase();
    final out = StringBuffer();
    for (final ch in lower.split('')) {
      final i = from.indexOf(ch);
      out.write(i < 0 ? ch : to[i]);
    }
    return out.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final q = _fold(_query.trim());
    final items = q.isEmpty
        ? _all!
        : _all!
            .where((e) =>
                e.$3.contains(q) || e.$1.countryCode.toLowerCase() == q)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.translate('chooseCountry'), style: t.titleLarge),
              const SizedBox(height: Space.m),
              TextField(
                controller: _search,
                autofocus: false,
                textInputAction: TextInputAction.search,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: l10n.translate('searchCountry'),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: l10n.translate('clear'),
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(() {
                            _search.clear();
                            _query = '';
                          }),
                        ),
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(l10n.translate('noCountryFound'),
                      style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: Space.s),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: items.length,
                  itemExtent: 56,
                  itemBuilder: (context, i) {
                    final (country, name, _) = items[i];
                    final selected = country.countryCode == widget.selected;
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: Space.page),
                      leading: SizedBox(
                        width: 32,
                        child: Center(
                          child: Text(country.flagEmoji,
                              style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                      title: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodyLarge?.copyWith(
                              fontWeight: selected ? FontWeight.w600 : null)),
                      trailing: selected
                          ? Icon(Icons.check_rounded, color: c.primary)
                          : null,
                      onTap: () => Navigator.of(context).pop(country),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
