class Zodiac {
  static String computeZodiac(DateTime birthDate) {
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
