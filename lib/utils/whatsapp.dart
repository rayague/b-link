/// Lien « click to chat » de WhatsApp.
///
/// Avec un numéro, la conversation s'ouvre directement ; sans numéro,
/// WhatsApp propose de choisir le destinataire. Le numéro doit être au
/// format international sans « + » : un numéro national (« 06 12… ») est
/// complété avec l'indicatif [dialCode] du pays de l'utilisateur.
Uri whatsappUri(String message, {String? phone, String? dialCode}) {
  final number = phone == null ? null : internationalDigits(phone, dialCode);
  return Uri.https('wa.me', number == null ? '/' : '/$number', {'text': message});
}

/// Chiffres du numéro au format international, ou null si on ne peut pas
/// le déduire (numéro national sans indicatif connu).
String? internationalDigits(String phone, String? dialCode) {
  final trimmed = phone.trim();
  var digits = trimmed.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 6) return null;
  if (trimmed.startsWith('+')) return digits;
  if (digits.startsWith('00')) return digits.substring(2);
  final code = dialCode?.replaceAll(RegExp(r'\D'), '');
  if (code == null || code.isEmpty) return null;
  if (digits.startsWith('0')) digits = digits.substring(1);
  return '$code$digits';
}
