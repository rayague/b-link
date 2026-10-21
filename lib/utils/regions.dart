/// Grandes régions du monde (continents), pour filtrer l'annuaire.
///
/// Codes : AF Afrique, AS Asie, EU Europe, NA Amérique du Nord (avec
/// l'Amérique centrale et les Caraïbes), SA Amérique du Sud, OC Océanie.
/// Doit rester aligné sur la liste acceptée par firestore.rules.
library;

const List<String> kRegions = ['AF', 'AS', 'EU', 'NA', 'SA', 'OC'];

const Map<String, String> _membersByRegion = {
  'AF': 'DZ AO BJ BW BF BI CV CM CF TD KM CG CD CI DJ EG GQ ER SZ ET GA GM '
      'GH GN GW KE LS LR LY MG MW ML MR MU YT MA MZ NA NE NG RE RW SH ST SN '
      'SC SL SO ZA SS SD TZ TG TN UG EH ZM ZW AC TA',
  'AS': 'AF AM AZ BH BD BT BN KH CN GE HK IN ID IR IQ IL JP JO KZ KW KG LA '
      'LB MO MY MV MN MM NP KP OM PK PS PH QA SA SG KR LK SY TW TJ TH TL TR '
      'TM AE UZ VN YE IO CC CX',
  'EU': 'AL AD AT BY BE BA BG HR CY CZ DK EE FO FI FR DE GI GR GG HU IS IE '
      'IM IT JE XK LV LI LT LU MT MD MC ME NL MK NO PL PT RO RU SM RS SK SI '
      'ES SJ SE CH UA GB VA AX',
  'NA': 'AI AG AW BS BB BZ BM BQ VG CA KY CR CU CW DM DO SV GL GD GP GT HT '
      'HN JM MQ MX MS NI PA PR BL KN LC MF PM VC SX TT TC US VI UM',
  'SA': 'AR BO BR CL CO EC FK GF GY PY PE SR UY VE GS',
  'OC': 'AS AU CK FJ PF GU KI MH FM NR NC NZ NU NF MP PW PG PN WS SB TK TO '
      'TV VU WF',
};

final Map<String, String> _regionByCountry = {
  for (final e in _membersByRegion.entries)
    for (final code in e.value.split(' '))
      if (code.isNotEmpty) code: e.key,
};

/// Région d'un pays (code ISO alpha-2), ou null (Antarctique, code inconnu).
String? regionOf(String? countryCode) =>
    countryCode == null ? null : _regionByCountry[countryCode.toUpperCase()];
