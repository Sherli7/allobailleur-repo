import 'package:flutter/material.dart';

class HelpSupportPage extends StatelessWidget {
  static const String routeName = '/helpSupport';

  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aide et Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Questions Fréquentes (FAQ)'),
          _buildExpansionTile(
            'Comment devenir bailleur ?',
            'Pour devenir bailleur, allez sur votre profil et cliquez sur "Devenir Bailleur". Remplissez les informations requises et soumettez votre demande.',
          ),
          _buildExpansionTile(
            'Comment contacter un propriétaire ?',
            'Sur la page d\'une annonce, cliquez sur le bouton "Contacter" ou l\'icône de message pour démarrer une conversation.',
          ),
          _buildExpansionTile(
            'Comment signaler un problème ?',
            'Allez dans la section "Incidents" de votre profil et cliquez sur le bouton "+" pour créer un nouveau ticket de signalement.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Contactez-nous'),
          _buildContactOption(
            context,
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: 'support@allobailleur.com',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ouverture de l\'application email...')),
              );
            },
          ),
          _buildContactOption(
            context,
            icon: Icons.phone_outlined,
            title: 'Téléphone',
            subtitle: '+237 690 00 00 00',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Appel en cours...')),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Documents Légaux'),
          ListTile(
            title: const Text('Conditions Générales d\'Utilisation'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Politique de Confidentialité'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildExpansionTile(String title, String content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              content,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
