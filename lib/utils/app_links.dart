/// Liens publics de l'app (partage, invitations).
class AppLinks {
  /// Page d'accueil (Firebase Hosting, dossier hosting/) : fonctionne avant
  /// même la publication sur les stores, et renvoie vers le Play Store.
  static const String website = 'https://b-link-3b2d5.web.app';

  /// Lien partagé dans les invitations.
  static const String invite = website;

  /// Fiche Google Play, déduite de l'applicationId (android/app/build.gradle.kts).
  /// Active dès la publication sur le Play Store.
  static const String store =
      'https://play.google.com/store/apps/details?id=com.rayague.b_link';

  /// Pages exigées par les stores (suppression de compte, confidentialité).
  static const String deleteAccount = '$website/delete-account';
  static const String privacy = '$website/privacy';
}
