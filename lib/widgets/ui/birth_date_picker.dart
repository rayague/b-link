import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/birthday.dart';
import 'glass.dart';

/// Choix d'une date de naissance en trois roues (jour, mois, année).
///
/// Le calendrier Material oblige à changer d'année puis à faire défiler les
/// mois un par un : beaucoup de gens validaient sans voir que le mois était
/// resté sur janvier. Ici, les trois valeurs sont visibles et réglables
/// directement.
///
/// [allowUnknownYear] ajoute « Année inconnue » (anniversaire d'un proche
/// dont on ignore l'année) : la date rendue porte alors [unknownBirthYear].
Future<DateTime?> showBirthDatePicker(
  BuildContext context, {
  DateTime? initial,
  bool allowUnknownYear = false,
  int? defaultYear,
}) {
  return showGlassSheet<DateTime>(
    context,
    builder: (_) => _BirthDatePicker(
      initial: initial,
      allowUnknownYear: allowUnknownYear,
      defaultYear: defaultYear,
    ),
  );
}

class _BirthDatePicker extends StatefulWidget {
  final DateTime? initial;
  final bool allowUnknownYear;
  final int? defaultYear;
  const _BirthDatePicker(
      {this.initial, required this.allowUnknownYear, this.defaultYear});

  @override
  State<_BirthDatePicker> createState() => _BirthDatePickerState();
}

class _BirthDatePickerState extends State<_BirthDatePicker> {
  static const _firstYear = 1900;
  static const _itemExtent = 44.0;

  late final DateTime _today = DateUtils.dateOnly(DateTime.now());

  /// Années proposées, la plus récente en haut ; null = année inconnue.
  late final List<int?> _years = [
    if (widget.allowUnknownYear) null,
    for (var y = _today.year; y >= _firstYear; y--) y,
  ];

  late int _day;
  late int _month;
  late int? _year;

  late final FixedExtentScrollController _dayCtrl;
  late final FixedExtentScrollController _monthCtrl;
  late final FixedExtentScrollController _yearCtrl;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _day = init?.day ?? 1;
    _month = init?.month ?? 1;
    if (init != null) {
      _year = hasBirthYear(init) ? init.year : null;
    } else {
      _year = widget.defaultYear ?? _today.year - 25;
    }
    if (_year == null && !widget.allowUnknownYear) _year = _today.year - 25;
    _dayCtrl = FixedExtentScrollController(initialItem: _day - 1);
    _monthCtrl = FixedExtentScrollController(initialItem: _month - 1);
    _yearCtrl = FixedExtentScrollController(
        initialItem: _years.indexOf(_year).clamp(0, _years.length - 1));
  }

  @override
  void dispose() {
    _dayCtrl.dispose();
    _monthCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  /// Jours du mois choisi. Année inconnue : le 29 février reste possible.
  int get _daysInMonth =>
      DateUtils.getDaysInMonth(_year ?? unknownBirthYear, _month);

  DateTime get _value =>
      DateTime(_year ?? unknownBirthYear, _month, _day.clamp(1, _daysInMonth));

  bool get _inFuture => _year != null && _value.isAfter(_today);

  void _setMonth(int month) {
    setState(() => _month = month);
    _clampDay();
  }

  void _setYear(int? year) {
    setState(() => _year = year);
    _clampDay();
  }

  /// 31 → 30 (ou 28) quand le mois choisi est plus court.
  void _clampDay() {
    final max = _daysInMonth;
    if (_day > max) {
      setState(() => _day = max);
      _dayCtrl.animateToItem(max - 1,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = l10n.locale.languageCode;
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final months = DateFormat.MMMM(lang);
    final summary = _year == null
        ? DateFormat.MMMMd(lang).format(_value)
        : DateFormat.yMMMMEEEEd(lang).format(_value);

    Widget wheel({
      required FixedExtentScrollController controller,
      required int count,
      required String Function(int) label,
      required ValueChanged<int> onChanged,
      bool Function(int)? disabled,
    }) =>
        CupertinoPicker.builder(
          scrollController: controller,
          itemExtent: _itemExtent,
          useMagnifier: true,
          magnification: 1.08,
          squeeze: 1.1,
          diameterRatio: 1.6,
          selectionOverlay: const SizedBox.shrink(),
          onSelectedItemChanged: onChanged,
          childCount: count,
          itemBuilder: (context, i) => Center(
            child: Text(
              label(i),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.titleMedium?.copyWith(
                color: disabled?.call(i) == true
                    ? c.onSurface.withValues(alpha: 0.3)
                    : c.onSurface,
              ),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.translate('birthDate'), style: t.titleLarge),
          const SizedBox(height: Space.xs),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.centerLeft,
              children: [...previous, if (current != null) current],
            ),
            child: Text(
              _inFuture ? l10n.translate('dateInFuture') : _capitalize(summary),
              key: ValueKey('$summary$_inFuture'),
              style: t.bodyLarge?.copyWith(
                  color: _inFuture ? c.error : c.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: Space.l),
          Row(
            children: [
              for (final (flex, key) in const [
                (2, 'pickerDay'),
                (4, 'pickerMonth'),
                (3, 'pickerYear'),
              ])
                Expanded(
                  flex: flex,
                  child: Text(l10n.translate(key),
                      textAlign: TextAlign.center,
                      style: t.labelMedium
                          ?.copyWith(color: c.onSurfaceVariant)),
                ),
            ],
          ),
          const SizedBox(height: Space.xs),
          SizedBox(
            height: _itemExtent * 5,
            child: Stack(
              children: [
                // Bande de sélection commune aux trois roues.
                Center(
                  child: Container(
                    height: _itemExtent,
                    decoration: BoxDecoration(
                      color: c.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(Radii.control),
                      border: Border.all(
                          color: c.primary.withValues(alpha: 0.18)),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: wheel(
                        controller: _dayCtrl,
                        count: 31,
                        label: (i) => '${i + 1}',
                        disabled: (i) => i + 1 > _daysInMonth,
                        onChanged: (i) {
                          setState(() => _day = i + 1);
                          if (_day > _daysInMonth) _clampDay();
                        },
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: wheel(
                        controller: _monthCtrl,
                        count: 12,
                        label: (i) =>
                            _capitalize(months.format(DateTime(2000, i + 1))),
                        onChanged: (i) => _setMonth(i + 1),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: wheel(
                        controller: _yearCtrl,
                        count: _years.length,
                        label: (i) => _years[i]?.toString() ??
                            l10n.translate('unknownYear'),
                        onChanged: (i) => _setYear(_years[i]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.xl),
          FilledButton(
            onPressed:
                _inFuture ? null : () => Navigator.of(context).pop(_value),
            child: Text(l10n.translate('confirm')),
          ),
        ],
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
