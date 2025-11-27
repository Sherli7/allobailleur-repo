import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:rent_house/Models/property.dart';
import 'package:rent_house/Providers/property_provider.dart';

class EditPropertyPage extends StatefulWidget {
  static const String routeName = '/editPropertyPageRoute';
  final Property property;

  const EditPropertyPage({super.key, required this.property});

  @override
  State<EditPropertyPage> createState() => _EditPropertyPageState();
}

class _EditPropertyPageState extends State<EditPropertyPage> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  final List<XFile> _newImages = [];
  late List<String> _existingImageUrls;

  // Step 1: Infos
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _propertyType;
  late TextEditingController _bedroomsController;
  late TextEditingController _bathroomsController;
  late TextEditingController _priceController;
  late String _currency;

  // Step 3: Localisation
  late TextEditingController _addressController;
  late TextEditingController _districtController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;

  // Step 4: Conditions
  late TextEditingController _conditionsController;
  late String _propertyStatus;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _existingImageUrls = List<String>.from(widget.property.imageUrls);
    _titleController = TextEditingController(text: widget.property.title);
    _descriptionController =
        TextEditingController(text: widget.property.description);
    _propertyType = widget.property.type;
    _bedroomsController =
        TextEditingController(text: widget.property.bedrooms.toString());
    _bathroomsController =
        TextEditingController(text: widget.property.bathrooms.toString());
    _priceController =
        TextEditingController(text: widget.property.price.toString());
    _currency = widget.property.currency;
    _addressController =
        TextEditingController(text: widget.property.address ?? '');
    _districtController =
        TextEditingController(text: widget.property.district ?? '');
    _latitudeController =
        TextEditingController(text: widget.property.latitude.toString());
    _longitudeController =
        TextEditingController(text: widget.property.longitude.toString());
    _conditionsController = TextEditingController(
      text: widget.property.conditions != null
          ? widget.property.conditions!['description'] ?? ''
          : '',
    );
    _propertyStatus = widget.property.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (!mounted) return;

      if (images.isNotEmpty) {
        setState(() {
          _newImages.addAll(images);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection: $e')),
        );
      }
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  Future<void> _saveProperty() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedProperty = Property(
        id: widget.property.id,
        ownerId: widget.property.ownerId,
        title: _titleController.text,
        description: _descriptionController.text,
        type: _propertyType,
        city: widget.property.city,
        country: widget.property.country,
        price: double.parse(_priceController.text),
        currency: _currency,
        rooms: int.parse(_bedroomsController.text),
        bathrooms: int.parse(_bathroomsController.text),
        address: _addressController.text,
        district: _districtController.text,
        surface: widget.property.surface,
        conditions: _conditionsController.text.isNotEmpty
            ? {'description': _conditionsController.text}
            : {},
        status: _propertyStatus,
        latitude: _latitudeController.text.isNotEmpty
            ? double.parse(_latitudeController.text)
            : 0.0,
        longitude: _longitudeController.text.isNotEmpty
            ? double.parse(_longitudeController.text)
            : 0.0,
        rating: widget.property.rating,
        reviewCount: widget.property.reviewCount,
        imageUrls: _existingImageUrls,
        amenities: widget.property.amenities,
        isAvailable: widget.property.isAvailable,
        createdAt: widget.property.createdAt,
        updatedAt: DateTime.now(),
      );

      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);
      await propertyProvider.updateProperty(
        widget.property.id,
        updatedProperty,
        newImages: _newImages.isNotEmpty ? _newImages : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Propriété mise à jour avec succès!')),
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier l\'Annonce'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 3) {
              setState(() => _currentStep++);
            } else {
              _saveProperty();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            }
          },
          steps: [
            Step(
              title: const Text('Informations'),
              content: _buildInfosStep(),
              isActive: _currentStep >= 0,
            ),
            Step(
              title: const Text('Photos'),
              content: _buildPhotosStep(),
              isActive: _currentStep >= 1,
            ),
            Step(
              title: const Text('Localisation'),
              content: _buildLocalisationStep(),
              isActive: _currentStep >= 2,
            ),
            Step(
              title: const Text('Résumé'),
              content: _buildResumeStep(),
              isActive: _currentStep >= 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfosStep() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Titre de l\'annonce',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Le titre est requis' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLines: 4,
            validator: (value) =>
                value?.isEmpty ?? true ? 'La description est requise' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _propertyType,
            decoration: InputDecoration(
              labelText: 'Type de propriété',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: ['apartment', 'house', 'studio', 'room', 'office']
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() => _propertyType = value ?? 'apartment');
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _bedroomsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Chambres',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Requis' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _bathroomsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Salles de bain',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Requis' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Prix',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Requis' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  initialValue: _currency,
                  decoration: InputDecoration(
                    labelText: 'Devise',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: ['XAF', 'USD', 'EUR']
                      .map((curr) => DropdownMenuItem(
                            value: curr,
                            child: Text(curr),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _currency = value ?? 'XAF');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPhotosStep() {
    final allImages = <Map<String, dynamic>>[
      ...List<Map<String, dynamic>>.generate(
        _existingImageUrls.length,
        (i) => {'type': 'existing', 'url': _existingImageUrls[i], 'index': i},
      ),
      ...List<Map<String, dynamic>>.generate(
        _newImages.length,
        (i) => {'type': 'new', 'xfile': _newImages[i], 'index': i},
      ),
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _pickImages,
            icon: const Icon(Icons.image_search),
            label: const Text('Ajouter des photos'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              backgroundColor: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 24),
          if (allImages.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune photo',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: allImages.length,
              itemBuilder: (context, index) {
                final img = allImages[index];
                final isExisting = img['type'] == 'existing';

                return Consumer<PropertyProvider>(builder: (context, prov, _) {
                  // Provider currently exposes a single uploadProgress double.
                  // Use it defensively here; per-file progress map can be added later.
                  final progress = isExisting ? null : prov.uploadProgress;

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image preview (existing or newly picked)
                      isExisting
                          ? Image.network(img['url'] as String,
                              fit: BoxFit.cover)
                          : FutureBuilder<Uint8List?>(
                              future: (img['xfile'] as XFile).readAsBytes(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                if (snapshot.hasData && snapshot.data != null) {
                                  return Image.memory(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                  );
                                }
                                return const Center(child: Icon(Icons.error));
                              },
                            ),

                      // Progress overlay for uploading new images
                      if (progress != null && progress < 1.0)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black45,
                            child: Center(
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 4,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Delete/remove button
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            if (isExisting) {
                              _removeExistingImage(img['index'] as int);
                            } else {
                              _removeNewImage(img['index'] as int);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade700,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                });
              },
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLocalisationStep() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Adresse',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? 'L\'adresse est requise' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _districtController,
            decoration: InputDecoration(
              labelText: 'Quartier/Arrondissement',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Le quartier est requis' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _latitudeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Latitude (optionnel)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _longitudeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Longitude (optionnel)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildResumeStep() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _resumeItem('Titre', _titleController.text),
                _resumeItem('Type', _propertyType),
                _resumeItem('Chambres', _bedroomsController.text),
                _resumeItem('Salles de bain', _bathroomsController.text),
                _resumeItem('Prix', '${_priceController.text} $_currency'),
                _resumeItem('Adresse', _addressController.text),
                _resumeItem('Quartier', _districtController.text),
                _resumeItem(
                  'Photos',
                  '${_existingImageUrls.length + _newImages.length} photo(s)',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          if (_isLoading)
            const CircularProgressIndicator()
          else
            ElevatedButton(
              onPressed: _saveProperty,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
              ),
              child: const Text(
                'Enregistrer les modifications',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _resumeItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
