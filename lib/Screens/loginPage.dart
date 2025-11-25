import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rent_house/Screens/guestHomePage.dart'; // Assure-toi du chemin correct
import 'package:rent_house/Providers/auth_provider.dart'
    as app_auth; // Alias pour ton custom AuthProvider

class LoginPage extends StatefulWidget {
  static const String routeName = '/login';
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // loading is read from AuthProvider now
  bool _obscurePassword = true;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    _controller.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Veuillez remplir tous les champs');
      return;
    }

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
      _showSnackBar(e.toString());
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Consumer<app_auth.AuthProvider>(
                      builder: (context, authProvider, _) {
                        final isLoading = authProvider.isLoading;
                        final error = authProvider.errorMessage;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.home,
                                    size: 36, color: Colors.blue),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'AllôBailleur',
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Connectez-vous pour continuer',
                              style: theme.textTheme.bodyMedium,
                            ),
                            if (error != null) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.error, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(error,
                                          style: const TextStyle(
                                              color: Colors.red))),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                ),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _login,
                                child: isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : const Text('Se connecter'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(children: const [
                              Expanded(child: Divider()),
                              Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('ou')),
                              Expanded(child: Divider())
                            ]),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: Image.asset(
                                    'assets/images/google_logo.png',
                                    width: 20,
                                    height: 20),
                                label: const Text('Continuer avec Google'),
                                onPressed: isLoading
                                    ? null
                                    : () async {
                                        final navigator = Navigator.of(context);
                                        final auth =
                                            Provider.of<app_auth.AuthProvider>(
                                                context,
                                                listen: false);
                                        final ok =
                                            await auth.signInWithGoogle();
                                        if (!mounted) return;
                                        if (ok) {
                                          navigator.pushReplacementNamed(
                                              GuestHomePage.routeName);
                                        }
                                      },
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Pas de compte ? "),
                                TextButton(
                                    onPressed: () => Navigator.pushNamed(
                                        context, '/register'),
                                    child: const Text('S\'inscrire')),
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
        ),
      ),
    );
  }
}
