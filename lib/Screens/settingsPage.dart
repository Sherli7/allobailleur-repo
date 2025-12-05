import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rent_house/Providers/auth_provider.dart';
import 'package:rent_house/Screens/helpSupportPage.dart';
import 'package:rent_house/Screens/personalInfoPage.dart';

class SettingsPage extends StatelessWidget {
  static const String routeName = '/settings';

  const SettingsPage({super.key});

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // L'utilisateur doit choisir une option
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer le compte'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Êtes-vous sûr de vouloir supprimer définitivement votre compte ?',
                ),
                SizedBox(height: 10),
                Text(
                  'Cette action est irréversible. Toutes vos données seront perdues.',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Ferme la boîte de dialogue
              },
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Supprimer'),
              onPressed: () {
                // TODO: Appeler le service de suppression de compte
                // await Provider.of<AuthProvider>(context, listen: false).deleteAccount();
                Navigator.of(dialogContext).pop(); // Ferme la boîte de dialogue
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Fonctionnalité de suppression en cours d'implémentation.",
                    ),
                  ),
                );
                // puis déconnecter et rediriger
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres'), centerTitle: true),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          _buildSectionHeader(context, 'Compte'),
          _buildSettingsTile(
            context,
            icon: Icons.person_outline,
            title: 'Informations personnelles',
            subtitle: 'Modifier votre profil',
            onTap: () =>
                Navigator.pushNamed(context, PersonalInfoPage.routeName),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.security,
            title: 'Sécurité',
            subtitle: 'Mot de passe, authentification',
            onTap: () {
              // TODO: Créer une page SecuritySettingsPage
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Navigation vers la page de sécurité...'),
                ),
              );
            },
          ),

          _buildSectionHeader(context, 'Préférences'),
          _buildSettingsTile(
            context,
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Gérer vos alertes',
            trailing: Switch(
              value: true, // Mock value
              onChanged: (val) {},
              activeColor: Theme.of(context).primaryColor,
            ),
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            icon: Icons.language,
            title: 'Langue',
            subtitle: 'Français',
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            icon: Icons.dark_mode_outlined,
            title: 'Thème sombre',
            subtitle: 'Désactivé',
            trailing: Switch(value: false, onChanged: (val) {}),
            onTap: () {},
          ),

          _buildSectionHeader(context, 'Assistance'),
          _buildSettingsTile(
            context,
            icon: Icons.help_outline,
            title: 'Aide et support',
            onTap: () =>
                Navigator.pushNamed(context, HelpSupportPage.routeName),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline,
            title: 'À propos de l\'application',
            subtitle: 'Version 1.0.0',
            onTap: () {},
          ),

          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              onPressed: () async {
                await Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).logout();
                if (context.mounted) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              },
              icon: const Icon(Icons.logout, color: Colors.amber),
              label: const Text(
                'Se déconnecter',
                style: TextStyle(color: Colors.amber),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.amber),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              onPressed: () => _showDeleteConfirmationDialog(context),
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text(
                'Supprimer mon compte',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
