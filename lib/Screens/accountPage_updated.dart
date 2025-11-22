import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:provider/provider.dart';
import 'package:rent_house/Screens/loginPage.dart';
import 'package:rent_house/Screens/personalInfoPage.dart';
import 'package:rent_house/Screens/viewProfilePage.dart';
import 'package:rent_house/Providers/auth_provider.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<AccountPage> {
  void _logout(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                await authProvider.logout();
                if (!mounted) return;
                navigator.pushReplacementNamed(LoginPage.routeName);
              },
              child: const Text('Déconnexion'),
            ),
          ],
        );
      },
    );
  }

  void _becomeHost(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Devenir hôte'),
          content: const Text(
              'Vous allez activé le mode hôte. Vous pourrez créer des annonces.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(dialogContext);
                final messenger = ScaffoldMessenger.of(context);
                final success = await authProvider.becomeHost();
                if (!mounted) return;

                navigator.pop();
                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(
                        content: Text('Vous êtes maintenant hôte!')),
                  );
                }
              },
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;

        if (user == null) {
          return const Center(
            child: Text('Utilisateur non trouvé'),
          );
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 50, 15, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Section Profil
                Padding(
                  padding: const EdgeInsets.only(bottom: 25.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      MaterialButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            ViewProfilePage.routeName,
                          );
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.black,
                          radius: MediaQuery.of(context).size.width / 9.5,
                          child: CircleAvatar(
                            radius: MediaQuery.of(context).size.width / 10,
                            backgroundImage: user.profileImageUrl.isNotEmpty
                                ? NetworkImage(user.profileImageUrl)
                                : const AssetImage('assets/images/sherli7.jpg')
                                    as ImageProvider,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            AutoSizeText(
                              user.fullName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            AutoSizeText(
                              user.email,
                              style: const TextStyle(fontSize: 15),
                            ),
                            if (user.isHost)
                              const Padding(
                                padding: EdgeInsets.only(top: 5.0),
                                child: Text(
                                  'Hôte',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Section Menu
                ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: <Widget>[
                    // Informations personnelles
                    MaterialButton(
                      height: MediaQuery.of(context).size.height / 9.0,
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          PersonalInfoPage.routeName,
                        );
                      },
                      child: const AccountPageListViewItem(
                        text: 'Informations personnelles',
                        iconData: Icons.person,
                      ),
                    ),
                    // Devenir hôte
                    if (!user.isHost)
                      MaterialButton(
                        height: MediaQuery.of(context).size.height / 9.0,
                        onPressed: () => _becomeHost(context),
                        child: const AccountPageListViewItem(
                          text: 'Devenir un hôte',
                          iconData: Icons.hotel,
                        ),
                      ),
                    // Mes annonces (si hôte)
                    if (user.isHost)
                      MaterialButton(
                        height: MediaQuery.of(context).size.height / 9.0,
                        onPressed: () {
                          // Naviguer vers la page des annonces
                        },
                        child: const AccountPageListViewItem(
                          text: 'Mes annonces',
                          iconData: Icons.apartment,
                        ),
                      ),
                    // Favoris
                    MaterialButton(
                      height: MediaQuery.of(context).size.height / 9.0,
                      onPressed: () {
                        // Naviguer vers les favoris
                      },
                      child: const AccountPageListViewItem(
                        text: 'Mes favoris',
                        iconData: Icons.favorite,
                      ),
                    ),
                    // Avis
                    MaterialButton(
                      height: MediaQuery.of(context).size.height / 9.0,
                      onPressed: () {
                        // Naviguer vers les avis
                      },
                      child: const AccountPageListViewItem(
                        text: 'Mes avis',
                        iconData: Icons.star,
                      ),
                    ),
                    // Déconnexion
                    MaterialButton(
                      height: MediaQuery.of(context).size.height / 9.0,
                      onPressed: () => _logout(context),
                      child: const AccountPageListViewItem(
                        text: 'Se déconnecter',
                        iconData: Icons.logout,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AccountPageListViewItem extends StatelessWidget {
  final String text;
  final IconData? iconData;

  const AccountPageListViewItem({
    required this.text,
    required this.iconData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 15.0),
            child: AutoSizeText(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          if (iconData != null)
            Padding(
              padding: const EdgeInsets.only(right: 15.0),
              child: Icon(iconData),
            ),
        ],
      ),
    );
  }
}
