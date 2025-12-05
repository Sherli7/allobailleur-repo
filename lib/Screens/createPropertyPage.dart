import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rent_house/Models/property.dart';
import 'package:rent_house/Providers/property_provider.dart';
import 'package:rent_house/Widgets/map_picker.dart';

class CreatePropertyPage extends StatefulWidget {
  static const routeName = '/create-property';
  const CreatePropertyPage({super.key});

  @override
  State<CreatePropertyPage> createState() => _CreatePropertyPageState();
}

class _CreatePropertyPageState extends State<CreatePropertyPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _roomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _livingRoomController = TextEditingController();
  final _surfaceController = TextEditingController();
  final _balconiesController = TextEditingController();
  final _leaseMonthsController = TextEditingController();
  final _depositController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  String _selectedType = 'Apartment';
  final List<String> _propertyTypes = ['Apartment', 'House', 'Villa', 'Studio', 'Office'];

  String _selectedCurrency = 'XAF';
  final List<String> _currencies = ['XAF', 'EUR', 'USD'];

  String? _selectedPowerType;
  final List<String> _powerTypes = ['prepaid', 'normal'];

  String? _selectedWaterSupplier;
  final List<String> _waterSuppliers = ['camwater', 'forage', 'other'];

  String? _selectedListingPurpose;
  final List<String> _listingPurposes = ['rent', 'sale'];

  String? _selectedStyle;
  final List<String> _styles = ['simple', 'modern', 'meublé', 'haut_standing'];

  final bool _furnishedNoDeposit = false;

  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // Location
  double _latitude = 3.8480;
  double _longitude = 11.5021;
  bool _locationSelected = false;

  @override
  void dispose() {
    // Dispose all controllers
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _roomsController.dispose();
    _bathroomsController.dispose();
    _livingRoomController.dispose();
    _surfaceController.dispose();
    _balconiesController.dispose();
    _leaseMonthsController.dispose();
    _depositController.dispose();
    _videoUrlController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() => _selectedImages.addAll(images));
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerPage(initialLat: _latitude, initialLng: _longitude),
      ),
    );

    if (result != null && result is MapPickerResult) {
      setState(() {
        _latitude = result.lat;
        _longitude = result.lng;
        _locationSelected = true;
        if (result.address != null) _addressController.text = result.address!;
      });
    }
  }

  Future<void> _submitProperty() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez ajouter au moins une image')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final property = Property(
        id: '',
        ownerId: user.id,
        title: _titleController.text,
        description: _descriptionController.text,
        type: _selectedType,
        price: double.parse(_priceController.text),
        currency: _selectedCurrency,
        surface: _surfaceController.text.isNotEmpty ? double.parse(_surfaceController.text) : null,
        rooms: int.parse(_roomsController.text),
        bathrooms: int.parse(_bathroomsController.text),
        balconies: _balconiesController.text.isNotEmpty ? int.parse(_balconiesController.text) : null,
        leaseMonths: _leaseMonthsController.text.isNotEmpty ? int.parse(_leaseMonthsController.text) : null,
        deposit: _depositController.text.isNotEmpty ? double.parse(_depositController.text) : null,
        powerType: _selectedPowerType,
        waterSupplier: _selectedWaterSupplier,
        furnishedNoDeposit: _furnishedNoDeposit,
        listingPurpose: _selectedListingPurpose,
        style: _selectedStyle,
        address: _addressController.text,
        city: _cityController.text,
        country: 'Cameroun',
        latitude: _latitude,
        longitude: _longitude,
        imageUrls: [],  // Vide, géré par provider
        videoUrl: _videoUrlController.text.isNotEmpty ? _videoUrlController.text : null,
        amenities: [],
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        rating: 0.0,
        reviewCount: 0,
        conditions: {
          'livingRooms': _livingRoomController.text.isNotEmpty ? int.parse(_livingRoomController.text) : 0,
        },
      );

      final provider = Provider.of<PropertyProvider>(context, listen: false);
      final res = await provider.createProperty(property, images: _selectedImages);

      if (res['success'] == true && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Propriété publiée avec succès !')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publier une annonce')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Images section
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: const Icon(Icons.add_a_photo, size: 30),
                      ),
                    );
                  }
                  final image = _selectedImages[index - 1];
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.file(File(image.path), fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => setState(() => _selectedImages.removeAt(index - 1)),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Titre et description
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Titre de l\'annonce', border: OutlineInputBorder()),
              validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            // Type
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(labelText: 'Type de bien', border: OutlineInputBorder()),
              items: _propertyTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
              onChanged: (val) => setState(() => _selectedType = val!),
            ),
            const SizedBox(height: 12),

            // Prix et devise
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Loyer', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCurrency,
                    decoration: const InputDecoration(labelText: 'Devise', border: OutlineInputBorder()),
                    items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setState(() => _selectedCurrency = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Caractéristiques
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _roomsController,
                    decoration: const InputDecoration(labelText: 'Chambres', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _bathroomsController,
                    decoration: const InputDecoration(labelText: 'Douches', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _livingRoomController,
                    decoration: const InputDecoration(labelText: 'Salons', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _balconiesController,
                    decoration: const InputDecoration(labelText: 'Balcons', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _surfaceController,
              decoration: const InputDecoration(labelText: 'Surface (m²)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),

            // Conditions
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _depositController,
                    decoration: const InputDecoration(labelText: 'Caution', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _leaseMonthsController,
                    decoration: const InputDecoration(labelText: 'Mois min.', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Autres détails
            DropdownButtonFormField<String>(
              initialValue: _selectedPowerType,
              decoration: const InputDecoration(labelText: 'Type d\'électricité', border: OutlineInputBorder()),
              items: _powerTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) => setState(() => _selectedPowerType = val),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedWaterSupplier,
              decoration: const InputDecoration(labelText: 'Eau', border: OutlineInputBorder()),
              items: _waterSuppliers.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) => setState(() => _selectedWaterSupplier = val),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: _selectedListingPurpose,
              decoration: const InputDecoration(labelText: 'Usage', border: OutlineInputBorder()),
              items: _listingPurposes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) => setState(() => _selectedListingPurpose = val),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: _selectedStyle,
              decoration: const InputDecoration(labelText: 'Style', border: OutlineInputBorder()),
              items: _styles.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) => setState(() => _selectedStyle = val),
            ),
            const SizedBox(height: 12),

            // Localisation
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'Ville', border: OutlineInputBorder()),
                    validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Quartier / Adresse', border: OutlineInputBorder()),
                    validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_locationSelected ? 'Position définie' : 'Positionner sur la carte'),
              subtitle: Text(_locationSelected ? '$_latitude, $_longitude' : 'Touchez pour choisir'),
              leading: Icon(Icons.map, color: _locationSelected ? Colors.green : Colors.grey),
              onTap: _pickLocation,
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitProperty,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Publier l\'annonce'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}