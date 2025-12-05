import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rent_house/Providers/auth_provider.dart';
import 'package:rent_house/Providers/property_provider.dart';
import 'package:rent_house/Screens/editPropertyPage.dart';
import 'package:rent_house/Screens/settingsPage.dart';
import 'package:rent_house/Screens/favoritesPage.dart';
import 'package:rent_house/Screens/ticketListPage.dart';
import 'package:rent_house/Screens/helpSupportPage.dart';
import 'package:rent_house/Screens/createPropertyPage.dart';
import 'package:rent_house/Screens/personalInfoPage.dart';

class ViewProfilePage extends StatefulWidget {
  static const String routeName = '/viewProfile';

  const ViewProfilePage({super.key});

  @override
  State<ViewProfilePage> createState() => _ViewProfilePageState();
}

class _ViewProfilePageState extends State<ViewProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.fetchUserProfile();

      // Charger les propriétés si l'utilisateur est propriétaire
      final user = authProvider.user;
      if (user != null && user.isHost) {
        context.read<PropertyProvider>().fetchUserProperties(user.uid);
      }
    });
  }
  
  void _showBecomeHostDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Devenir un bailleur ?'),
          content: const Text("Vous êtes sur le point de passer en mode bailleur. Cela vous donnera accès à la publication et à la gestion d'annonces. Voulez-vous continuer ?"),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Confirmer'),
              onPressed: () async {
                Navigator.of(context).pop();
                await Provider.of<AuthProvider>(context, listen: false).becomeHost();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Félicitations ! Vous êtes maintenant un bailleur.')),
                );
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (authProvider.isLoading && user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Impossible de charger le profil")),
      );
    }

    final bool isHost = user.isHost;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // En-tête profil
          SliverAppBar(
            expandedHeight: 200.0,
            pinned: true,
            backgroundColor: Theme.of(context).primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withBlue(100),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white,
                          backgroundImage: (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty)
                              ? NetworkImage(user.profileImageUrl!)
                              : const AssetImage('assets/images/defaultAvatar.jpg') as ImageProvider,
                        ),
                        if (user.kycStatus == 'verified')
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified,
                                color: Colors.blue,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isHost ? 'Bailleur' : 'Locataire',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage())),
                tooltip: 'Paramètres',
              ),
            ],
          ),

          // Grille d'actions rapides
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Raccourcis'),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      _buildActionCard(
                        context,
                        icon: Icons.favorite,
                        color: Colors.pink,
                        label: 'Favoris',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritesPage())),
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.report_problem,
                        color: Colors.orange,
                        label: 'Incidents',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TicketListPage())),
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.person,
                        color: Colors.blue,
                        label: 'Infos Perso',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalInfoPage())),
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.help,
                        color: Colors.green,
                        label: 'Aide',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportPage())),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Section Devenir Propriétaire
          if (!isHost)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Icon(Icons.switch_account_outlined, color: Theme.of(context).primaryColor),
                    title: const Text('Devenir un bailleur', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Publiez et gérez vos propres annonces.'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _showBecomeHostDialog,
                  ),
                ),
              ),
            ),

          // Section Bio
          if (user.bio != null && user.bio!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('À propos'),
                    const SizedBox(height: 8),
                    Text(
                      user.bio!,
                      style: TextStyle(color: Colors.grey[700], height: 1.5),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

          // Section Propriétaire (si applicable)
          if (isHost) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle('Mes Annonces'),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePropertyPage())),
                      child: const Text('Ajouter'),
                    ),
                  ],
                ),
              ),
            ),
            Consumer<PropertyProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                }

                final myProperties = provider.userProperties;

                if (myProperties == null || myProperties.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.house_outlined,
                              size: 48,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Vous n'avez aucune annonce.",
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final property = myProperties[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(10),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            property.imageUrls.isNotEmpty
                                ? property.imageUrls.first
                                : 'https://via.placeholder.com/100',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[300],
                              width: 60,
                              height: 60,
                            ),
                          ),
                        ),
                        title: Text(
                          property.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${property.city} • ${property.price} FCFA',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => EditPropertyPage(property: property)),
                          ),
                        ),
                      ),
                    );
                  }, childCount: myProperties.length),
                );
              },
            ),
          ],

          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
