import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rent_house/Models/property.dart';
import 'package:rent_house/Providers/property_provider.dart';
import 'package:rent_house/Widgets/map_picker.dart';
import 'package:provider/provider.dart';

class EditPropertyPage extends StatefulWidget {
  static const routeName = '/edit-property';
  final Property property;

  const EditPropertyPage({super.key, required this.property});

  @override
  State<EditPropertyPage> createState() => _EditPropertyPageState();
}

class _EditPropertyPageState extends State<EditPropertyPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late String _type;
  List<String> _images = [];
  final List<XFile> _selectedNewImages = [];  // Nouvelles images à uploader
  final ImagePicker _picker = ImagePicker();
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.property.title);
    _descriptionController = TextEditingController(text: widget.property.description);
    _priceController = TextEditingController(text: widget.property.price.toString());
    _addressController = TextEditingController(text: widget.property.address);
    _cityController = TextEditingController(text: widget.property.city);
    _type = widget.property.type;
    _images = List.from(widget.property.imageUrls);
    _latitude = widget.property.latitude;
    _longitude = widget.property.longitude;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickNewImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() => _selectedNewImages.addAll(images));
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerPage(
          initialLat: _latitude ?? 3.8480,
          initialLng: _longitude ?? 11.5021,
        ),
      ),
    );

    if (result != null && result is MapPickerResult) {
      setState(() {
        _latitude = result.lat;
        _longitude = result.lng;
        if (result.address != null) _addressController.text = result.address!;
      });
    }
  }

  Future<void> _saveProperty() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner un emplacement sur la carte')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedProperty = Property(
        id: widget.property.id,
        ownerId: widget.property.ownerId,
        title: _titleController.text,
        description: _descriptionController.text,
        type: _type,
        price: double.tryParse(_priceController.text) ?? 0.0,
        address: _addressController.text,
        city: _cityController.text,
        country: widget.property.country,
        latitude: _latitude!,
        longitude: _longitude!,
        imageUrls: _images,  // Images existantes
        amenities: widget.property.amenities,
        isAvailable: widget.property.isAvailable,
        createdAt: widget.property.createdAt,
        updatedAt: DateTime.now(),
        rating: widget.property.rating,
        reviewCount: widget.property.reviewCount,
        bathrooms: widget.property.bathrooms,
        // Ajoute les autres champs si besoin (surface, rooms, etc.)
      );

      final provider = Provider.of<PropertyProvider>(context, listen: false);
      final res = await provider.updateProperty(
        updatedProperty.id,
        updatedProperty,
        newImages: _selectedNewImages.isNotEmpty ? _selectedNewImages : null,
      );

      if (res['success'] == true && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Propriété mise à jour avec succès')));
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
      appBar: AppBar(title: const Text('Modifier la propriété')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Images existantes + nouvelles
            const Text('Images actuelles :'),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        child: Image.network(_images[index], fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => setState(() => _images.removeAt(index)),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            const Text('Ajouter de nouvelles images :'),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedNewImages.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return GestureDetector(
                      onTap: _pickNewImages,
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
                  final image = _selectedNewImages[index - 1];
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        child: Image.file(File(image.path), fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => setState(() => _selectedNewImages.removeAt(index - 1)),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Titre'),
              validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
              validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Prix (FCFA)'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: ['Apartment', 'House', 'Villa', 'Studio', 'Office']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) => setState(() => _type = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'Ville'),
              validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Adresse / Quartier'),
              validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('Emplacement sur la carte'),
              subtitle: Text(_latitude != null ? 'Lat: $_latitude, Lng: $_longitude' : 'Non défini'),
              trailing: const Icon(Icons.map),
              tileColor: Colors.grey[100],
              onTap: _pickLocation,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProperty,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isLoading ? const CircularProgressIndicator() : const Text('Enregistrer les modifications'),
            ),
          ],
        ),
      ),
    );
  }
}