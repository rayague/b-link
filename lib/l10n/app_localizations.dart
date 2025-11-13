import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'B-Link',
      'home': 'Home',
      'contacts': 'Contacts',
      'celebrations': 'Celebrations',
      'settings': 'Settings',
      'changeTheme': 'Change Theme',
      'changeLanguage': 'Change Language',
      'dark': 'Dark',
      'light': 'Light',
      'system': 'System',
      'welcome': 'Welcome',
      'getStarted': 'Get Started',
      'skip': 'Skip',
      'next': 'Next',
      'onboarding1Title': 'Never Forget a Birthday',
      'onboarding1Body':
          'Keep track of all your friends and family birthdays in one place',
      'onboarding2Title': 'Smart Reminders',
      'onboarding2Body':
          'Get timely notifications so you never miss an important date',
      'onboarding3Title': 'Personalized Messages',
      'onboarding3Body':
          'Generate heartfelt messages for each special person in your life',

      // Common
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'confirm': 'Confirm',
      'close': 'Close',
      'back': 'Back',
      'viewAll': 'View All',
      'search': 'Search',
      'noResults': 'No results',

      // Profile
      'myProfile': 'My Profile',
      'profileSaved': '✅ Profile saved successfully',
      'chooseBirthDate': 'Please choose your birth date',
      'fullName': 'Full name',
      'birthDate': 'Birth date',
      'birthTime': 'Birth time (optional)',
      'socialLink': 'Social network link',
      'recommendApp': 'Recommend the app',
      'shareWithFriends': 'Share B-Link with your friends',
      'selectDate': 'Select a date',
      'selectTime': 'Select a time',

      // Contacts
      'myContacts': 'My Contacts',
      'searchContact': 'Search a contact...',
      'addContact': 'Add contact',
      'contactAdded': 'added successfully',
      'contactDeleted': 'deleted',
      'contactUpdated': '✅ Contact updated',
      'enterName': 'Please enter a name',
      'selectBirthDate': 'Please select a date',
      'deleteContact': 'Delete',
      'confirmDelete': 'Confirm',
      'noContact': 'No contact',
      'pressToAdd': 'Press + to add',
      'tryAnotherSearch': 'Try another search',
      'phone': 'Phone (optional)',
      'relation': 'Relation',
      'selectRelation': 'Select a relation',
      'pickPhoto': 'Pick photo',
      'contactInfo': 'Contact information',
      'update': 'Update',

      // Same Day
      'sameDay': 'Same Day 🎂',
      'peopleCount': 'people',
      'shareYourBirthday': 'share your birthday',
      'publicProfiles': '👥 Public profiles',
      'noProfileFound': 'No profile found',
      'beTheFirst': 'Be the first to share!',
      'viewProfile': 'View profile',
      'contactPerson': 'Contact',

      // Zodiac
      'yourZodiacSign': 'Your Zodiac Sign',
      'zodiacQuotes': 'Daily Quotes',
      'learnMore': 'Learn More',

      // Notifications
      'birthdayReminder': 'Birthday Reminder',
      'todayBirthday': 'Today is',
      'tomorrowBirthday': 'Tomorrow is',
      'upcomingBirthday': 'Upcoming birthday',

      // Authentication
      'login': 'Login',
      'signup': 'Sign Up',
      'welcomeBack': 'Welcome back! 👋',
      'createAccount': 'Create your account 🎉',
      'loginSubtitle': 'Sign in to continue',
      'signupSubtitle': 'Join us now',
      'email': 'Email',
      'password': 'Password',
      'loginButton': 'Sign in',
      'signupButton': 'Create my account',
      'enterEmail': 'Please enter your email',
      'invalidEmail': 'Invalid email',
      'enterPassword': 'Please enter your password',
      'minCharacters': 'Minimum 6 characters',
      'forgotPassword': 'Forgot password?',
      'noAccount': 'No account yet?',
      'alreadyRegistered': 'Already registered?',
      'switchToSignup': 'Sign up',
      'switchToLogin': 'Sign in',
    },
    'fr': {
      'appTitle': 'B-Link',
      'home': 'Accueil',
      'contacts': 'Contacts',
      'celebrations': 'Célébrations',
      'settings': 'Paramètres',
      'changeTheme': 'Changer le thème',
      'changeLanguage': 'Changer la langue',
      'dark': 'Sombre',
      'light': 'Clair',
      'system': 'Système',
      'welcome': 'Bienvenue',
      'getStarted': 'Commencer',
      'skip': 'Passer',
      'next': 'Suivant',
      'onboarding1Title': 'N\'oubliez Plus Aucun Anniversaire',
      'onboarding1Body':
          'Gardez tous les anniversaires de vos proches en un seul endroit',
      'onboarding2Title': 'Rappels Intelligents',
      'onboarding2Body':
          'Recevez des notifications pour ne jamais manquer une date importante',
      'onboarding3Title': 'Messages Personnalisés',
      'onboarding3Body':
          'Générez des messages sincères pour chaque personne spéciale',

      // Common
      'save': 'Sauvegarder',
      'cancel': 'Annuler',
      'delete': 'Supprimer',
      'edit': 'Modifier',
      'add': 'Ajouter',
      'confirm': 'Confirmer',
      'close': 'Fermer',
      'back': 'Retour',
      'viewAll': 'Voir tout',
      'search': 'Rechercher',
      'noResults': 'Aucun résultat',

      // Profile
      'myProfile': 'Mon Profil',
      'profileSaved': '✅ Profil sauvegardé avec succès',
      'chooseBirthDate': 'Veuillez choisir votre date de naissance',
      'fullName': 'Nom complet',
      'birthDate': 'Date de naissance',
      'birthTime': 'Heure de naissance (optionnel)',
      'socialLink': 'Lien réseau social',
      'recommendApp': 'Recommander l\'application',
      'shareWithFriends': 'Partagez B-Link avec vos amis',
      'selectDate': 'Sélectionner une date',
      'selectTime': 'Sélectionner une heure',

      // Contacts
      'myContacts': 'Mes Contacts',
      'searchContact': 'Rechercher un contact...',
      'addContact': 'Ajouter un contact',
      'contactAdded': 'ajouté avec succès',
      'contactDeleted': 'supprimé',
      'contactUpdated': '✅ Contact mis à jour',
      'enterName': 'Veuillez entrer un nom',
      'selectBirthDate': 'Veuillez sélectionner une date',
      'deleteContact': 'Supprimer',
      'confirmDelete': 'Confirmer',
      'noContact': 'Aucun contact',
      'pressToAdd': 'Appuyez sur + pour ajouter',
      'tryAnotherSearch': 'Essayez une autre recherche',
      'phone': 'Téléphone (optionnel)',
      'relation': 'Relation',
      'selectRelation': 'Sélectionner une relation',
      'pickPhoto': 'Choisir une photo',
      'contactInfo': 'Informations du contact',
      'update': 'Mettre à jour',

      // Same Day
      'sameDay': 'Même Jour 🎂',
      'peopleCount': 'personnes',
      'shareYourBirthday': 'partagent votre anniversaire',
      'publicProfiles': '👥 Profils publics',
      'noProfileFound': 'Aucun profil trouvé',
      'beTheFirst': 'Soyez le premier à partager !',
      'viewProfile': 'Voir le profil',
      'contactPerson': 'Contacter',

      // Zodiac
      'yourZodiacSign': 'Votre Signe Astrologique',
      'zodiacQuotes': 'Citations du Jour',
      'learnMore': 'En Savoir Plus',

      // Notifications
      'birthdayReminder': 'Rappel d\'Anniversaire',
      'todayBirthday': 'Aujourd\'hui c\'est l\'anniversaire de',
      'tomorrowBirthday': 'Demain c\'est l\'anniversaire de',
      'upcomingBirthday': 'Anniversaire à venir',

      // Authentication
      'login': 'Connexion',
      'signup': 'Inscription',
      'welcomeBack': 'Bon retour parmi nous! 👋',
      'createAccount': 'Créez votre compte 🎉',
      'loginSubtitle': 'Connectez-vous pour continuer',
      'signupSubtitle': 'Rejoignez-nous dès maintenant',
      'email': 'Email',
      'password': 'Mot de passe',
      'loginButton': 'Se connecter',
      'signupButton': 'Créer mon compte',
      'enterEmail': 'Veuillez entrer votre email',
      'invalidEmail': 'Email invalide',
      'enterPassword': 'Veuillez entrer votre mot de passe',
      'minCharacters': 'Minimum 6 caractères',
      'forgotPassword': 'Mot de passe oublié?',
      'noAccount': 'Pas encore de compte?',
      'alreadyRegistered': 'Déjà inscrit?',
      'switchToSignup': 'S\'inscrire',
      'switchToLogin': 'Se connecter',
    }
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'fr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      true;
}
