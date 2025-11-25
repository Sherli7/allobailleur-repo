import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Removed google_fonts and local_auth to avoid extra dependencies
// import 'package:google_fonts/google_fonts.dart'; // Ajoutez ce package
import 'dart:ui' show ImageFilter;
import 'package:rent_house/Screens/guestHomePage.dart';
import 'package:rent_house/Providers/auth_provider.dart' as app_auth;

class LoginPage extends StatefulWidget {
  static const String routeName = '/login';
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _staggerController;
  late List<Animation<double>> _staggerAnimations;
  // Biometric login removed (not configured in this project)

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    // Animation staggerée pour entrée séquentielle
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    final staggerCurve = Interval(0.0, 1.0, curve: Curves.easeInOut);
    _staggerAnimations = List.generate(
      5,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _staggerController, curve: staggerCurve),
      ),
    );

    _controller.forward().then((_) => _staggerController.forward());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _controller.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider =
        Provider.of<app_auth.AuthProvider>(context, listen: false);
    try {
      await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, GuestHomePage.routeName);
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              Color(0xFF0D47A1), // Bleu foncé
              Color(0xFF1976D2), // Bleu principal
              Color(0xFF42A5F5), // Bleu clair
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isTablet = constraints.maxWidth > 600;
                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 600 : 520,
                        maxHeight: isTablet ? 700 : double.infinity,
                      ),
                      child: Card(
                        elevation: 0,
                        color: Colors.white.withOpacity(0.1), // Glassmorphism
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side:
                              BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                        margin: EdgeInsets.symmetric(
                          horizontal: isTablet ? 40 : 20,
                          vertical: isTablet ? 20 : 40,
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Padding(
                            padding: EdgeInsets.all(isTablet ? 40 : 32),
                            child: Form(
                              key: _formKey,
                              child: Consumer<app_auth.AuthProvider>(
                                builder: (context, authProvider, _) {
                                  final isLoading = authProvider.isLoading;
                                  final error = authProvider.errorMessage;
                                  if (error != null) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (mounted) _showError(error);
                                    });
                                  }

                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Logo avec animation stagger
                                      FadeTransition(
                                        opacity: _staggerAnimations[0],
                                        child: ScaleTransition(
                                          scale: _staggerAnimations[0].drive(
                                            Tween(begin: 0.8, end: 1.0),
                                          ),
                                          child: Container(
                                            width: 90,
                                            height: 90,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                colors: [
                                                  theme.colorScheme.primary,
                                                  theme.colorScheme.primary
                                                      .withOpacity(0.7),
                                                ],
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.home,
                                              size: 50,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      // Titre avec stagger
                                      FadeTransition(
                                        opacity: _staggerAnimations[1],
                                        child: SlideTransition(
                                          position: _staggerAnimations[1].drive(
                                            Tween<Offset>(
                                              begin: const Offset(0, 0.2),
                                              end: Offset.zero,
                                            ),
                                          ),
                                          child: Text(
                                            'AllôBailleur',
                                            style: theme.textTheme.headlineLarge
                                                ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      FadeTransition(
                                        opacity: _staggerAnimations[1],
                                        child: Text(
                                          'Connectez-vous pour continuer',
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                            color:
                                                Colors.white.withOpacity(0.8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      // Email field avec focus animation
                                      FadeTransition(
                                        opacity: _staggerAnimations[2],
                                        child: SlideTransition(
                                          position: _staggerAnimations[2].drive(
                                            Tween<Offset>(
                                              begin: const Offset(0, 0.1),
                                              end: Offset.zero,
                                            ),
                                          ),
                                          child: TextFormField(
                                            controller: _emailController,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            autovalidateMode: AutovalidateMode
                                                .onUserInteraction,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty)
                                                return 'Email requis';
                                              if (!RegExp(
                                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                                  .hasMatch(value))
                                                return 'Email invalide';
                                              return null;
                                            },
                                            decoration: InputDecoration(
                                              labelText: 'Email',
                                              labelStyle:
                                                  theme.textTheme.bodyMedium,
                                              prefixIcon: Icon(
                                                  Icons.email_outlined,
                                                  color: theme
                                                      .colorScheme.primary),
                                              suffixIcon: _emailController
                                                          .text.isNotEmpty &&
                                                      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                                          .hasMatch(
                                                              _emailController
                                                                  .text)
                                                  ? const Icon(
                                                      Icons.check_circle,
                                                      color: Colors.green,
                                                      semanticLabel: 'Valide')
                                                  : null,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                borderSide: BorderSide(
                                                    color: Colors.white
                                                        .withOpacity(0.3)),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                borderSide: BorderSide(
                                                    color: theme
                                                        .colorScheme.primary,
                                                    width: 2),
                                              ),
                                              filled: true,
                                              fillColor:
                                                  Colors.white.withOpacity(0.9),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Password field
                                      FadeTransition(
                                        opacity: _staggerAnimations[2],
                                        child: SlideTransition(
                                          position: _staggerAnimations[2].drive(
                                            Tween<Offset>(
                                              begin: const Offset(0, 0.1),
                                              end: Offset.zero,
                                            ),
                                          ),
                                          child: TextFormField(
                                            controller: _passwordController,
                                            obscureText: _obscurePassword,
                                            autovalidateMode: AutovalidateMode
                                                .onUserInteraction,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty)
                                                return 'Mot de passe requis';
                                              if (value.length < 6)
                                                return 'Min 6 caractères';
                                              return null;
                                            },
                                            decoration: InputDecoration(
                                              labelText: 'Mot de passe',
                                              labelStyle:
                                                  theme.textTheme.bodyMedium,
                                              prefixIcon: Icon(
                                                  Icons.lock_outline,
                                                  color: theme
                                                      .colorScheme.primary),
                                              suffixIcon: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  _passwordController
                                                              .text.length >=
                                                          6
                                                      ? const Icon(
                                                          Icons.check_circle,
                                                          color: Colors.green,
                                                          size: 20)
                                                      : const SizedBox(
                                                          width: 0),
                                                  IconButton(
                                                    icon: Icon(
                                                      _obscurePassword
                                                          ? Icons.visibility_off
                                                          : Icons.visibility,
                                                      color: Colors.grey[600],
                                                    ),
                                                    onPressed: () => setState(
                                                        () => _obscurePassword =
                                                            !_obscurePassword),
                                                  ),
                                                ],
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                borderSide: BorderSide(
                                                    color: Colors.white
                                                        .withOpacity(0.3)),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                borderSide: BorderSide(
                                                    color: theme
                                                        .colorScheme.primary,
                                                    width: 2),
                                              ),
                                              filled: true,
                                              fillColor:
                                                  Colors.white.withOpacity(0.9),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () => Navigator.pushNamed(
                                              context,
                                              '/forgot-password'), // Route à ajouter
                                          child: Text(
                                            'Mot de passe oublié ?',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      // Bouton principal avec dégradé
                                      FadeTransition(
                                        opacity: _staggerAnimations[3],
                                        child: SlideTransition(
                                          position: _staggerAnimations[3].drive(
                                            Tween<Offset>(
                                              begin: const Offset(0, 0.2),
                                              end: Offset.zero,
                                            ),
                                          ),
                                          child: SizedBox(
                                            width: double.infinity,
                                            height: 56,
                                            child: ElevatedButton(
                                              onPressed:
                                                  isLoading ? null : _login,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.transparent,
                                                shadowColor: theme
                                                    .colorScheme.primary
                                                    .withOpacity(0.3),
                                                elevation: 8,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                              ),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      theme.colorScheme.primary,
                                                      theme.colorScheme.primary
                                                          .withOpacity(0.8),
                                                    ],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                child: isLoading
                                                    ? const Center(
                                                        child: SizedBox(
                                                          width: 24,
                                                          height: 24,
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            valueColor:
                                                                AlwaysStoppedAnimation<
                                                                        Color>(
                                                                    Colors
                                                                        .white),
                                                          ),
                                                        ),
                                                      )
                                                    : const Center(
                                                        child: Text(
                                                          'Se connecter',
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: const [
                                          Expanded(
                                              child: Divider(
                                                  color: Colors.white24)),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 16),
                                            child: Text('ou',
                                                style: TextStyle(
                                                    color: Colors.white54)),
                                          ),
                                          Expanded(
                                              child: Divider(
                                                  color: Colors.white24)),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // Bouton Google
                                      FadeTransition(
                                        opacity: _staggerAnimations[4],
                                        child: SlideTransition(
                                          position: _staggerAnimations[4].drive(
                                            Tween<Offset>(
                                              begin: const Offset(0, 0.2),
                                              end: Offset.zero,
                                            ),
                                          ),
                                          child: SizedBox(
                                            width: double.infinity,
                                            height: 56,
                                            child: OutlinedButton.icon(
                                              icon: Image.asset(
                                                'assets/images/google_logo.png',
                                                width: 20,
                                                height: 20,
                                              ),
                                              label: Text(
                                                'Continuer avec Google',
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(fontSize: 16),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                side: BorderSide(
                                                    color: Colors.white
                                                        .withOpacity(0.3)),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                              ),
                                              onPressed: isLoading
                                                  ? null
                                                  : () async {
                                                      final navigator =
                                                          Navigator.of(context);
                                                      final auth = Provider.of<
                                                              app_auth
                                                              .AuthProvider>(
                                                          context,
                                                          listen: false);
                                                      final ok = await auth
                                                          .signInWithGoogle();
                                                      if (!mounted) return;
                                                      if (ok) {
                                                        navigator
                                                            .pushReplacementNamed(
                                                                GuestHomePage
                                                                    .routeName);
                                                      }
                                                    },
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Bouton biométrie (optionnel)
                                      if (MediaQuery.of(context).size.width <
                                          600) // Seulement mobile
                                        TextButton.icon(
                                          icon: const Icon(Icons.fingerprint,
                                              color: Colors.white54, size: 20),
                                          label: Text(
                                            'Connexion biométrique',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                            ),
                                          ),
                                          onPressed: isLoading
                                              ? null
                                              : () => _showError(
                                                  'Biometric login removed'),
                                        ),
                                      const SizedBox(height: 24),
                                      // Lien inscription
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Pas de compte ? ",
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                    color: Colors.white
                                                        .withOpacity(0.7)),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pushNamed(
                                                    context, '/register'),
                                            child: Text(
                                              'S\'inscrire',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
