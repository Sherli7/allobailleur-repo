import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rent_house/Models/Users.dart';
import 'package:rent_house/Providers/auth_provider.dart';
import 'package:rent_house/Views/text_widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PersonalInfoPage extends StatefulWidget {
  static const String routeName = '/personalInfoPageRoute';

  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _MyPersonalInfoPageState();
}

class _MyPersonalInfoPageState extends State<PersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Pré-remplir les champs avec les données actuelles de l'utilisateur
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user != null) {
        _firstNameController.text = user.fullName;
        _emailController.text = user.email;
        _cityController.text = user.city ?? '';
        _countryController.text = user.country ?? '';
        _bioController.text = user.bio ?? '';
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpdateProfileImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() => _isLoading = true);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final success = await authProvider.updateProfileImage(pickedFile);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo de profil mise à jour avec succès')),
          );
        } else {
          throw Exception('Échec de l\'upload de l\'image');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveInfo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Mettre à jour les informations de l'utilisateur
      await authProvider.updateUserProfile(
        fullName: _firstNameController.text.trim(),
        email: _emailController.text.trim(),
        city: _cityController.text.trim(),
        country: _countryController.text.trim(),
        bio: _bioController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès')),
        );
        Navigator.of(context).pop(); // Retourner à la page précédente
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à jour: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildVerificationStatus(User user) {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    String description;

    switch (user.kycStatus) {
      case 'verified':
        statusColor = Colors.green;
        statusText = 'Identité vérifiée';
        statusIcon = Icons.verified_user;
        description =
            'Votre identité a été confirmée. Vous bénéficiez du badge de confiance.';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Vérification en cours';
        statusIcon = Icons.hourglass_top;
        description =
            'Vos documents sont en cours d\'examen par notre équipe.';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Vérification rejetée';
        statusIcon = Icons.error_outline;
        description =
            'Votre demande a été rejetée. Veuillez vérifier vos documents et réessayer.';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Non vérifié';
        statusIcon = Icons.gpp_maybe;
        description =
            'Faites vérifier votre identité pour rassurer les autres utilisateurs et obtenir le badge "Vérifié".';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor),
              const SizedBox(width: 10),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description),
          if (user.kycStatus == null || user.kycStatus == 'rejected') ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fonctionnalité à venir: Upload de CNI/Passeport')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Vérifier mon identité'),
            ),
          ]
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: AppBarText(key: UniqueKey(), text: 'Informations personnelles'),
        actions: <Widget>[
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(
                Icons.save,
                color: Colors.white,
              ),
              onPressed: _saveInfo,
              tooltip: 'Sauvegarder',
            )
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(25, 25, 25, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty)
                                ? NetworkImage(user.profileImageUrl!)
                                : const AssetImage('assets/images/defaultAvatar.jpg') as ImageProvider,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Material(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                onTap: _pickAndUpdateProfileImage,
                                borderRadius: BorderRadius.circular(20),
                                child: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildVerificationStatus(user),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 15.0),
                              child: TextFormField(
                                controller: _firstNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Nom complet',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person),
                                ),
                                style: const TextStyle(fontSize: 16.0),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Le nom complet est requis';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 25.0),
                              child: TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.email),
                                ),
                                style: const TextStyle(fontSize: 16.0),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "L'email est requis";
                                  }
                                  if (!RegExp(
                                          r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$")
                                      .hasMatch(value)) {
                                    return 'Veuillez entrer un email valide';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 25.0),
                              child: TextFormField(
                                controller: _cityController,
                                decoration: const InputDecoration(
                                  labelText: 'Ville',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.location_city),
                                ),
                                style: const TextStyle(fontSize: 16.0),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 25.0),
                              child: TextFormField(
                                controller: _countryController,
                                decoration: const InputDecoration(
                                  labelText: 'Pays',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.flag),
                                ),
                                style: const TextStyle(fontSize: 16.0),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 25.0),
                              child: TextFormField(
                                controller: _bioController,
                                decoration: const InputDecoration(
                                  labelText: 'Biographie',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.description),
                                  alignLabelWithHint: true,
                                ),
                                style: const TextStyle(fontSize: 16.0),
                                maxLines: 3,
                                maxLength: 500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _saveInfo,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save),
                          label: Text(_isLoading
                              ? 'Sauvegarde en cours...'
                              : 'Sauvegarder les modifications'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
