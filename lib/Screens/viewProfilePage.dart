import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rent_house/Providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rent_house/Providers/property_provider.dart';
import 'package:rent_house/Models/property.dart';
import 'package:rent_house/Views/text_widgets.dart';
import 'package:rent_house/Screens/owner_dashboard.dart';

class ViewProfilePage extends StatefulWidget {
  static const String routeName = '/viewProfilePageRoute';

  const ViewProfilePage({super.key});

  @override
  State<ViewProfilePage> createState() => _MyViewProfilePageState();
}

class _MyViewProfilePageState extends State<ViewProfilePage> {
  bool _loadingProperties = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user != null) {
        // Capture provider before awaiting to avoid using BuildContext across async gaps
        final propertyProvider =
            Provider.of<PropertyProvider>(context, listen: false);
        await propertyProvider.loadHostProperties(user.uid);
      }
      if (mounted) setState(() => _loadingProperties = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: AppBarText(key: UniqueKey(), text: user.fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.pushNamed(context, '/personalInfo'),
            tooltip: 'Éditer le profil',
          ),
          IconButton(
            icon: const Icon(Icons.dashboard),
            onPressed: () =>
                Navigator.pushNamed(context, OwnerDashboard.routeName),
            tooltip: 'Tableau de bord',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar with edit button
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: user.profileImageUrl.isNotEmpty
                          ? NetworkImage(user.profileImageUrl)
                          : const AssetImage(
                                  'assets/images/default_profile.jpg')
                              as ImageProvider,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () async {
                            // Capture navigator/messenger/providers before any await
                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(context);
                            final authProv = Provider.of<AuthProvider>(context,
                                listen: false);
                            final picker = ImagePicker();

                            final XFile? picked = await picker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 1200,
                              maxHeight: 1200,
                              imageQuality: 85,
                            );
                            if (picked == null) return;

                            // Show modal progress using the captured NavigatorState
                            final loaderRoute = PageRouteBuilder<void>(
                              opaque: false,
                              pageBuilder: (_, __, ___) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                            navigator.push(loaderRoute);

                            final success =
                                await authProv.updateProfileImage(picked);

                            // Use captured navigator/messenger rather than context
                            if (navigator.mounted) navigator.pop();

                            messenger.showSnackBar(SnackBar(
                                content: Text(success
                                    ? 'Photo de profil mise à jour'
                                    : 'Échec de l\'upload')));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).colorScheme.surfaceVariant,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.edit,
                              size: 18,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName,
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text(user.email,
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      Text(user.isHost == true ? 'Hôte' : 'Locataire',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('À propos', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(user.bio ?? 'Aucune description fournie',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            Text('Localisation', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              (user.city != null && user.country != null)
                  ? '${user.city}, ${user.country}'
                  : 'Non spécifiée',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Text('Mes annonces', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Consumer<PropertyProvider>(
              builder: (context, provider, child) {
                if (_loadingProperties) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = provider.userProperties ?? [];
                if (list.isEmpty) {
                  return const Text('Vous n\'avez pas d\'annonces.');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final Property p = list[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: p.imageUrls.isNotEmpty
                            ? Image.network(p.imageUrls.first,
                                width: 72, height: 72, fit: BoxFit.cover)
                            : Container(
                                width: 72, height: 72, color: Colors.grey[200]),
                        title: Text(p.title),
                        subtitle: Text(
                            '${p.city} • ${p.price.toStringAsFixed(0)} € • ${p.status}'),
                        onTap: () => Navigator.pushNamed(
                            context, '/viewPosting',
                            arguments: p),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'mark_rented') {
                              final messenger = ScaffoldMessenger.of(context);
                              final ok = await provider.completeRental(p);
                              if (mounted) {
                                messenger.showSnackBar(SnackBar(
                                    content: Text(ok
                                        ? 'Annonce marquée louée'
                                        : 'Échec')));
                              }
                            } else if (value == 'restore') {
                              final messenger = ScaffoldMessenger.of(context);
                              final ok = await provider.restoreProperty(p);
                              if (mounted) {
                                messenger.showSnackBar(SnackBar(
                                    content: Text(ok
                                        ? 'Annonce remise en ligne'
                                        : 'Échec')));
                              }
                            } else if (value == 'edit') {
                              if (mounted) {
                                Navigator.pushNamed(context, '/editProperty',
                                    arguments: p);
                              }
                            } else if (value == 'delete') {
                              final messenger = ScaffoldMessenger.of(context);
                              final res = await provider.deleteProperty(p.id);
                              if (res['success'] == true) {
                                // Reload provider lists via provider methods
                                final uid = user.uid;
                                await provider.loadHostProperties(uid);
                                await provider.fetchProperties();
                                if (mounted) {
                                  messenger.showSnackBar(const SnackBar(
                                      content: Text('Annonce supprimée')));
                                }
                              } else {
                                if (mounted) {
                                  messenger.showSnackBar(SnackBar(
                                      content: Text(
                                          'Erreur: ${res['message'] ?? ''}')));
                                }
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            if (p.status != 'rented')
                              const PopupMenuItem(
                                  value: 'mark_rented',
                                  child: Text('Marquer loué')),
                            if (p.status == 'rented')
                              const PopupMenuItem(
                                  value: 'restore',
                                  child: Text('Remettre en ligne')),
                            const PopupMenuItem(
                                value: 'edit', child: Text('Éditer')),
                            const PopupMenuItem(
                                value: 'delete', child: Text('Supprimer')),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
