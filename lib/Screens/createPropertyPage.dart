import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreatePropertyPage extends StatefulWidget {
  static const String routeName = '/create-property';
  const CreatePropertyPage({super.key});

  @override
  State<CreatePropertyPage> createState() => _CreatePropertyPageState();
}

class _CreatePropertyPageState extends State<CreatePropertyPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  int _currentStep = 0;
  bool _isLoading = false;

  // --- Données du formulaire ---
  String? _propertyType = 'apartment'; // apartment, studio, villa, house, guest_house, office, land, shop
  String _transactionType = 'rent'; // Toujours 'rent' pour Allo Bailleur pour le moment

  // Localisation
  final _cityController = TextEditingController();
  final _districtController = TextEditingController(); // Quartier
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  // Détails
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String _currency = 'XAF'; // XAF, EUR, USD
  final _surfaceController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();

  // Spécifique Location
  final _leaseMonthsController = TextEditingController(); // Durée du bail min
  final _depositController = TextEditingController(); // Caution
  String _powerType = 'normal'; // normal, prepaid
  String _waterSupplier = 'camwater'; // camwater, forage, other
  
  // Meublé
  bool _isFurnished = false;
  String _furnishedPeriodUnit = 'month'; // day, week, month (si meublé)

  // Style & Commodités
  String _style = 'modern';
  final List<String> _selectedAmenities = [];

  // Photos
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _cityController.dispose();
    _districtController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _surfaceController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _leaseMonthsController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  // --- Gestion des Images ---

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((e) => File(e.path)));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection d\'images: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // --- Soumission ---

  Future<void> _submitProperty() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedImages.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter au moins une photo.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // 1. Upload des images vers Supabase Storage
      final List<String> imageUrls = [];
      for (var file in _selectedImages) {
        final String fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
        await _supabase.storage.from('properties').upload(fileName, file);
        final String publicUrl = _supabase.storage.from('properties').getPublicUrl(fileName);
        imageUrls.add(publicUrl);
      }

      // 2. Insertion en base de données
      final propertyData = {
        'ownerId': user.id,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'type': _propertyType, 
        'city': _cityController.text,
        'district': _districtController.text,
        'address': _addressController.text,
        'country': 'Cameroun', 
        'price': double.tryParse(_priceController.text) ?? 0,
        'currency': _currency,
        'surface': double.tryParse(_surfaceController.text) ?? 0,
        'bedrooms': int.tryParse(_bedroomsController.text) ?? 0,
        'bathrooms': int.tryParse(_bathroomsController.text) ?? 0,
        
        'leaseMonths': int.tryParse(_leaseMonthsController.text),
        'deposit': double.tryParse(_depositController.text),
        'powerType': _powerType,
        'waterSupplier': _waterSupplier,
        'isFurnished': _isFurnished,
        'furnishedPeriodUnit': _isFurnished ? _furnishedPeriodUnit : null,
        
        'style': _style,
        'amenities': _selectedAmenities,
        'imageUrls': imageUrls,
        'isAvailable': true,
        
        'latitude': double.tryParse(_latitudeController.text),
        'longitude': double.tryParse(_longitudeController.text),
        
        'status': 'published',
        'createdAt': DateTime.now().toIso8601String(),
      };

      await _supabase.from('properties').insert(propertyData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Propriété publiée avec succès !')),
        );
        Navigator.pop(context); 
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI Steps ---

  List<Step> _getSteps() {
    return [
      Step(
        title: const Text('Type'),
        content: _buildTypeStep(),
        isActive: _currentStep >= 0,
      ),
      Step(
        title: const Text('Infos'),
        content: _buildInfosStep(),
        isActive: _currentStep >= 1,
      ),
      Step(
        title: const Text('Photos'),
        content: _buildPhotosStep(),
        isActive: _currentStep >= 2,
      ),
      Step(
        title: const Text('Lieu'),
        content: _buildLocalisationStep(),
        isActive: _currentStep >= 3,
      ),
      Step(
        title: const Text('Résumé'),
        content: _buildResumeStep(),
        isActive: _currentStep >= 4,
      ),
    ];
  }

  Widget _buildTypeStep() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _propertyType,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Type de propriété',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: const [
            DropdownMenuItem(value: 'apartment', child: Text('Appartement')),
            DropdownMenuItem(value: 'studio', child: Text('Studio')),
            DropdownMenuItem(value: 'villa', child: Text('Villa')),
            DropdownMenuItem(value: 'house', child: Text('Maison')),
            DropdownMenuItem(value: 'guest_house', child: Text('Maison d\'hôtes (Meublé)')),
            DropdownMenuItem(value: 'office', child: Text('Bureau')),
            DropdownMenuItem(value: 'shop', child: Text('Commerce')),
            DropdownMenuItem(value: 'land', child: Text('Terrain')),
          ],
          onChanged: (val) => setState(() => _propertyType = val),
        ),
        const SizedBox(height: 16),
        if (_propertyType == 'apartment') ...[
          DropdownButtonFormField<String>(
            value: _style,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Style de l\'appartement',
               border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: const [
              DropdownMenuItem(value: 'modern', child: Text('Moderne')),
              DropdownMenuItem(value: 'classic', child: Text('Classique')),
              DropdownMenuItem(value: 'luxury', child: Text('Haut Standing')),
            ],
            onChanged: (val) => setState(() => _style = val!),
          ),
        ] else if (_propertyType == 'studio') ...[
           DropdownButtonFormField<String>(
            value: _style,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Style du studio',
               border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: const [
              DropdownMenuItem(value: 'modern', child: Text('Moderne')),
              DropdownMenuItem(value: 'americain', child: Text('Américain (Cuisine ouverte)')),
              DropdownMenuItem(value: 'standard', child: Text('Standard')),
            ],
            onChanged: (val) => setState(() => _style = val!),
          ),
        ],
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text('Meublé ?'),
          value: _isFurnished,
          onChanged: (val) => setState(() => _isFurnished = val ?? false),
        ),
        if (_isFurnished)
           DropdownButtonFormField<String>(
            value: _furnishedPeriodUnit,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Unité de location'),
            items: const [
              DropdownMenuItem(value: 'day', child: Text('Par jour (Courte durée)')),
              DropdownMenuItem(value: 'month', child: Text('Par mois (Longue durée)')),
            ],
            onChanged: (val) => setState(() => _furnishedPeriodUnit = val!),
          ),
      ],
    );
  }

  Widget _buildInfosStep() {
    return Column(
      children: [
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(labelText: 'Titre de l\'annonce', hintText: 'Ex: Superbe 3 pièces Bastos'),
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(labelText: 'Description complète'),
          maxLines: 3,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Loyer / Prix'),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _currency,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'XAF', child: Text('XAF')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                ],
                onChanged: (val) => setState(() => _currency = val!),
                decoration: const InputDecoration(labelText: 'Devise'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _surfaceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Surface (m²)'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _bedroomsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Chambres'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _bathroomsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Douches'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Conditions & Commodités', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _depositController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Caution (XAF)'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _powerType,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Type de courant'),
                items: const [
                  DropdownMenuItem(value: 'normal', child: Text('Compteur normal')),
                  DropdownMenuItem(value: 'prepaid', child: Text('Compteur prépayé')),
                ],
                onChanged: (val) => setState(() => _powerType = val!),
              ),
            ),
          ],
        ),
         const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _waterSupplier,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Fournisseur d\'eau'),
            items: const [
              DropdownMenuItem(value: 'camwater', child: Text('Camwater')),
              DropdownMenuItem(value: 'forage', child: Text('Forage')),
              DropdownMenuItem(value: 'other', child: Text('Autre')),
            ],
            onChanged: (val) => setState(() => _waterSupplier = val!),
          ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            'Wifi', 'Climatisation', 'Parking', 'Groupe électrogène', 'Gardien', 'Balcon', 'Piscine'
          ].map((amenity) {
            final isSelected = _selectedAmenities.contains(amenity);
            return FilterChip(
              label: Text(amenity),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedAmenities.add(amenity);
                  } else {
                    _selectedAmenities.remove(amenity);
                  }
                });
              },
            );
          }).toList(),
        )
      ],
    );
  }

  Widget _buildPhotosStep() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_a_photo),
          label: const Text('Ajouter des photos'),
        ),
        const SizedBox(height: 10),
        if (_selectedImages.isEmpty)
          const Text('Aucune photo sélectionnée')
        else
          SizedBox(
            height: 200,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_selectedImages[index], fit: BoxFit.cover),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          color: Colors.black54,
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildLocalisationStep() {
    return Column(
      children: [
        TextFormField(
          controller: _cityController,
          decoration: const InputDecoration(labelText: 'Ville'),
           validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _districtController,
          decoration: const InputDecoration(labelText: 'Quartier'),
           validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
         const SizedBox(height: 12),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(labelText: 'Adresse précise / Repère'),
        ),
         const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _latitudeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Latitude (Optionnel)'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _longitudeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Longitude (Optionnel)'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Astuce: Vous pouvez laisser Lat/Long vides si vous ne les connaissez pas.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildResumeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Titre: ${_titleController.text}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text('Type: $_propertyType - $_style'),
        Text('Prix: ${_priceController.text} $_currency'),
        Text('Lieu: ${_cityController.text}, ${_districtController.text}'),
        const SizedBox(height: 10),
        Text('Photos: ${_selectedImages.length} sélectionnée(s)'),
        const SizedBox(height: 20),
        const Text('Vérifiez les informations avant de publier.', style: TextStyle(color: Colors.orange)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une propriété'),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          type: StepperType.horizontal,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < _getSteps().length - 1) {
              setState(() => _currentStep += 1);
            } else {
              _submitProperty();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep -= 1);
            } else {
              Navigator.pop(context);
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Row(
                children: [
                   if (_isLoading)
                      const CircularProgressIndicator()
                   else ...[
                      ElevatedButton(
                        onPressed: details.onStepContinue,
                        child: Text(_currentStep == _getSteps().length - 1 ? 'Publier' : 'Suivant'),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Retour'),
                      ),
                   ]
                ],
              ),
            );
          },
          steps: _getSteps(),
        ),
      ),
    );
  }
}
