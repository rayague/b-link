import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _error = null;
    });
    _slideController.reset();
    _slideController.forward();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final email = _emailCtrl.text.trim();
    final pw = _pwCtrl.text;
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      if (_isLogin) {
        final ok = await auth.login(email, pw);
        if (!mounted) return;

        if (ok) {
          Navigator.of(context).pushReplacementNamed('/');
        } else {
          setState(() => _error = 'Email ou mot de passe incorrect');
        }
      } else {
        await auth.register(email, pw);
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/profile-register');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1E3A8A), const Color(0xFF1F2937)]
                : [
                    const Color(0xFF3B82F6),
                    const Color(0xFF60A5FA),
                    const Color(0xFFEFF6FF)
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo & Title Section
                      _buildHeader(),
                      SizedBox(height: size.height * 0.05),

                      // Main Card with Form
                      _buildAuthCard(isDark),

                      const SizedBox(height: 24),

                      // Toggle Login/Register
                      _buildToggleButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Animated Logo Container
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEC4899), Color(0xFFF472B6), Color(0xFFFBBF24)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEC4899).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.cake_rounded,
            size: 50,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),

        // App Title
        const Text(
          'B-Link',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle
        Text(
          _isLogin
              ? AppLocalizations.of(context).translate('welcomeBack')
              : AppLocalizations.of(context).translate('createAccount'),
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthCard(bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 450),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                _isLogin
                    ? AppLocalizations.of(context).translate('login')
                    : AppLocalizations.of(context).translate('signup'),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin
                    ? AppLocalizations.of(context).translate('loginSubtitle')
                    : AppLocalizations.of(context).translate('signupSubtitle'),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Email Field
              _buildTextField(
                controller: _emailCtrl,
                label: AppLocalizations.of(context).translate('email'),
                hint: 'votre@email.com',
                icon: Icons.email_rounded,
                isDark: isDark,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context).translate('enterEmail');
                  }
                  if (!value.contains('@')) {
                    return AppLocalizations.of(context)
                        .translate('invalidEmail');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Password Field
              _buildTextField(
                controller: _pwCtrl,
                label: AppLocalizations.of(context).translate('password'),
                hint: '••••••••',
                icon: Icons.lock_rounded,
                isDark: isDark,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)
                        .translate('enterPassword');
                  }
                  if (!_isLogin && value.length < 6) {
                    return AppLocalizations.of(context)
                        .translate('minCharacters');
                  }
                  return null;
                },
              ),

              // Forgot Password (only for login)
              if (_isLogin) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      // Afficher un dialogue pour entrer l'email
                      final email = await showDialog<String>(
                        context: context,
                        builder: (context) => _ForgotPasswordDialog(
                          initialEmail: _emailCtrl.text.trim(),
                        ),
                      );

                      if (email == null || email.isEmpty) return;

                      // Montrer un indicateur de chargement
                      if (mounted) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      try {
                        print('🔄 Tentative d\'envoi email de réinitialisation à: $email');
                        
                        await FirebaseAuth.instance.sendPasswordResetEmail(
                          email: email,
                        );

                        print('✅ Email de réinitialisation envoyé avec succès à: $email');

                        // Fermer l'indicateur de chargement
                        if (mounted) Navigator.of(context).pop();

                        if (mounted) {
                          // Afficher un dialogue de succès détaillé
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.mark_email_read_rounded,
                                      color: Color(0xFF10B981),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      AppLocalizations.of(context)
                                          .locale
                                          .languageCode == 'fr'
                                          ? 'Email envoyé! ✅'
                                          : 'Email sent! ✅',
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ],
                              ),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context).locale.languageCode == 'fr'
                                          ? 'Un email de réinitialisation a été envoyé à:'
                                          : 'A reset email has been sent to:',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.email_outlined, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              email,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.blue[200]!,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.info_outline,
                                                  color: Colors.blue[700], size: 18),
                                              const SizedBox(width: 6),
                                              Text(
                                                AppLocalizations.of(context)
                                                            .locale
                                                            .languageCode ==
                                                        'fr'
                                                    ? 'Que faire maintenant?'
                                                    : 'What to do next?',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue[700],
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            AppLocalizations.of(context)
                                                        .locale
                                                        .languageCode ==
                                                    'fr'
                                                ? '1. Vérifiez votre boîte mail\n2. Vérifiez aussi les SPAMS\n3. Cliquez sur le lien reçu\n4. Créez votre nouveau mot de passe'
                                                : '1. Check your inbox\n2. Also check SPAM folder\n3. Click the link received\n4. Create your new password',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                              height: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text(
                                    AppLocalizations.of(context).translate('close'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                        // Fermer l'indicateur de chargement
                        if (mounted) Navigator.of(context).pop();
                        
                        print('❌ Erreur Firebase: ${e.code} - ${e.message}');
                        String errorMessage;
                        String errorDetails = '';
                        
                        switch (e.code) {
                          case 'user-not-found':
                            errorMessage = AppLocalizations.of(context)
                                .translate('emailNotFound');
                            errorDetails = AppLocalizations.of(context)
                                        .locale
                                        .languageCode ==
                                    'fr'
                                ? 'Aucun compte n\'existe avec cet email. Veuillez créer un compte d\'abord.'
                                : 'No account exists with this email. Please create an account first.';
                            break;
                          case 'invalid-email':
                            errorMessage = AppLocalizations.of(context)
                                .translate('invalidEmail');
                            errorDetails = AppLocalizations.of(context)
                                        .locale
                                        .languageCode ==
                                    'fr'
                                ? 'Le format de l\'email est invalide.'
                                : 'The email format is invalid.';
                            break;
                          default:
                            errorMessage = 'Error [${e.code}]';
                            errorDetails = e.message ?? '';
                        }

                        if (mounted) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.error_outline,
                                      color: Color(0xFFEF4444),
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      errorMessage,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ],
                              ),
                              content: Text(errorDetails),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text(
                                    AppLocalizations.of(context).translate('close'),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      } catch (e) {
                        // Fermer l'indicateur de chargement
                        if (mounted) Navigator.of(context).pop();
                        
                        print('❌ Erreur inattendue: $e');
                        
                        // Détecter erreur réseau
                        String errorMessage;
                        String errorDetails;
                        bool isNetworkError = e.toString().contains('connection') ||
                            e.toString().contains('network') ||
                            e.toString().contains('abort');
                        
                        if (isNetworkError) {
                          errorMessage = AppLocalizations.of(context)
                                      .locale
                                      .languageCode ==
                                  'fr'
                              ? 'Erreur de connexion'
                              : 'Connection Error';
                          errorDetails = AppLocalizations.of(context)
                                      .locale
                                      .languageCode ==
                                  'fr'
                              ? 'Vérifiez votre connexion internet et réessayez.\n\nSi le problème persiste:\n• Essayez avec WiFi ou données mobiles\n• Redémarrez l\'application\n• Vérifiez que Firebase est accessible'
                              : 'Check your internet connection and try again.\n\nIf the issue persists:\n• Try WiFi or mobile data\n• Restart the app\n• Verify Firebase is accessible';
                        } else {
                          errorMessage = AppLocalizations.of(context)
                                      .locale
                                      .languageCode ==
                                  'fr'
                              ? 'Erreur inattendue'
                              : 'Unexpected Error';
                          errorDetails = e.toString();
                        }
                        
                        if (mounted) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      isNetworkError ? Icons.wifi_off : Icons.error_outline,
                                      color: const Color(0xFFEF4444),
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      errorMessage,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                              content: SingleChildScrollView(
                                child: Text(
                                  errorDetails,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text(
                                    AppLocalizations.of(context).translate('close'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    },
                    child: Text(
                      AppLocalizations.of(context).translate('forgotPassword'),
                      style: const TextStyle(
                        color: Color(0xFF3B82F6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Error Message
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_rounded,
                          color: Color(0xFFEF4444), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Submit Button
              _buildSubmitButton(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
    Widget? suffixIcon,
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
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
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
            suffixIcon: suffixIcon,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
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

  Widget _buildSubmitButton(bool isDark) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLogin
                        ? AppLocalizations.of(context).translate('loginButton')
                        : AppLocalizations.of(context)
                            .translate('signupButton'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isLogin
                ? AppLocalizations.of(context).translate('noAccount')
                : AppLocalizations.of(context).translate('alreadyRegistered'),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _toggleMode,
            child: Text(
              _isLogin
                  ? AppLocalizations.of(context).translate('switchToSignup')
                  : AppLocalizations.of(context).translate('switchToLogin'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Dialogue pour "Mot de passe oublié"
class _ForgotPasswordDialog extends StatefulWidget {
  final String initialEmail;

  const _ForgotPasswordDialog({required this.initialEmail});

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lock_reset, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              loc.translate('forgotPassword'),
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.locale.languageCode == 'fr'
                ? 'Entrez votre adresse email pour recevoir un lien de réinitialisation.'
                : 'Enter your email address to receive a reset link.',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            decoration: InputDecoration(
              labelText: loc.translate('email'),
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.translate('cancel')),
        ),
        ElevatedButton(
          onPressed: () {
            final email = _emailController.text.trim();
            if (email.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(loc.translate('enterEmailForReset')),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }
            Navigator.of(context).pop(email);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            loc.locale.languageCode == 'fr'
                ? 'Envoyer le lien'
                : 'Send Link',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
