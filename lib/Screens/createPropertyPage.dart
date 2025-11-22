import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:rent_house/Models/property.dart';
import 'package:rent_house/Providers/auth_provider.dart' as app_auth;
import 'package:rent_house/Providers/property_provider.dart';

class CreatePropertyPage extends StatefulWidget {
  static const String routeName = '/createPropertyPageRoute';
  const CreatePropertyPage({super.key});

  @override
  State<CreatePropertyPage> createState() => _CreatePropertyPageState();
}

class _CreatePropertyPageState extends State<CreatePropertyPage> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  final List<XFile> _selectedImages = [];
  // Form keys per step for proper validation
  final List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(), // step 0 - Informations
    GlobalKey<FormState>(), // step 1 - Photos
    GlobalKey<FormState>(), // step 2 - Localisation
    GlobalKey<FormState>(), // step 3 - Résumé
  ];
  // Focus nodes and field keys to focus/scroll to invalid fields
  late final FocusNode _titleFocus;
  late final FocusNode _descriptionFocus;
  late final FocusNode _bedroomsFocus;
  late final FocusNode _bathroomsFocus;
  late final FocusNode _priceFocus;
  late final FocusNode _surfaceFocus;
  late final FocusNode _addressFocus;
  late final FocusNode _districtFocus;

  final GlobalKey<FormFieldState> _titleFieldKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _descriptionFieldKey =
      GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _bedroomsFieldKey =
      GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _bathroomsFieldKey =
      GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _priceFieldKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _surfaceFieldKey =
      GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _addressFieldKey =
      GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _districtFieldKey =
      GlobalKey<FormFieldState>();

  // Step 1: Infos
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  String _propertyType = 'apartment'; // apartment, house, studio, room, office
  late final TextEditingController _bedroomsController;
  late final TextEditingController _bathroomsController;
  late final TextEditingController _priceController;
  late final TextEditingController _surfaceController;
  String _currency = 'XAF';
  // New fields
  late final TextEditingController _balconiesController;
  late final TextEditingController _leaseMonthsController;
  late final TextEditingController _depositController;
  String _powerType = 'normal'; // 'normal' or 'prepaid'
  String _waterSupplier = 'camwater'; // 'camwater' or 'forage' or 'other'
  String _furnishedPeriodUnit = 'month'; // 'day','week','month','year'
  bool _furnishedNoDeposit = false;
  String _listingPurpose = 'rent'; // 'rent' or 'sale'
  String _style = 'simple';

  // Step 3: Localisation (optional lat/lng for now; integrate map later)
  late final TextEditingController _addressController;
  late final TextEditingController _districtController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;

  // Step 4: Conditions & Amenities
  late final TextEditingController _conditionsController;
  final String _propertyStatus = 'published';
  final List<String> _selectedAmenities =
      []; // e.g., ['wifi', 'parking', 'pool']

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _bedroomsController = TextEditingController(text: '1');
    _bathroomsController = TextEditingController(text: '1');
    _priceController = TextEditingController();
    _surfaceController = TextEditingController();
    _balconiesController = TextEditingController(text: '0');
    _leaseMonthsController = TextEditingController(text: '12');
    _depositController = TextEditingController();
    _addressController = TextEditingController();
    _districtController = TextEditingController();
    _latitudeController = TextEditingController();
    _longitudeController = TextEditingController();
    _conditionsController = TextEditingController();
    // init focus nodes
    _titleFocus = FocusNode();
    _descriptionFocus = FocusNode();
    _bedroomsFocus = FocusNode();
    _bathroomsFocus = FocusNode();
    _priceFocus = FocusNode();
    _surfaceFocus = FocusNode();
    _addressFocus = FocusNode();
    _districtFocus = FocusNode();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _priceController.dispose();
    _surfaceController.dispose();
    // dispose focus nodes
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    _bedroomsFocus.dispose();
    _bathroomsFocus.dispose();
    _priceFocus.dispose();
    _surfaceFocus.dispose();
    _addressFocus.dispose();
    _districtFocus.dispose();
    _balconiesController.dispose();
    _leaseMonthsController.dispose();
    _depositController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images =
          await _imagePicker.pickMultiImage(imageQuality: 85);
      // Guard against widget being disposed while awaiting
      if (!mounted) return;

      if (images.isNotEmpty) {
        if (_selectedImages.length + images.length <= 10) {
          setState(() => _selectedImages.addAll(images));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ajouté ${images.length} photo(s)')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Limite de 10 photos atteinte')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<void> _publishProperty() async {
    if (!_formKey.currentState!.validate() || _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez remplir tous les champs requis')),
      );
      return;
    }

    final authProvider =
        Provider.of<app_auth.AuthProvider>(context, listen: false);
    if (authProvider.firebaseUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur non authentifié')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Parse values safely
      final bedrooms = int.parse(_bedroomsController.text);
      final bathrooms = int.parse(_bathroomsController.text);
      final price = double.parse(_priceController.text);
      final surface = double.tryParse(_surfaceController.text);
      final latitude = double.tryParse(_latitudeController.text) ?? 0.0;
      final longitude = double.tryParse(_longitudeController.text) ?? 0.0;
      final balconies = int.tryParse(_balconiesController.text) ?? 0;
      final leaseMonths = int.tryParse(_leaseMonthsController.text);
      final deposit = double.tryParse(_depositController.text);

      final property = Property(
        id: '',
        ownerId: authProvider.firebaseUser!.uid,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _propertyType,
        city: authProvider.user?.city ?? '',
        country: authProvider.user?.country ?? '',
        price: price,
        surface: surface,
        currency: _currency,
        bedrooms: bedrooms,
        bathrooms: bathrooms,
        balconies: balconies,
        leaseMonths: leaseMonths,
        deposit: deposit,
        powerType: _powerType,
        waterSupplier: _waterSupplier,
        furnishedPeriodUnit: _furnishedPeriodUnit,
        furnishedNoDeposit: _furnishedNoDeposit,
        listingPurpose: _listingPurpose,
        style: _style,
        address: _addressController.text.trim(),
        district: _districtController.text.trim(),
        conditions: _conditionsController.text.trim().isNotEmpty
            ? {'description': _conditionsController.text.trim()}
            : {},
        status: _propertyStatus,
        latitude: latitude,
        longitude: longitude,
        rating: 0,
        reviewCount: 0,
        imageUrls: [],
        amenities: _selectedAmenities,
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);

      // Show progress dialog for image upload
      if (_selectedImages.isNotEmpty) {
        // Temporarily skip storage test to avoid initialization issues
        debugPrint('Skipping storage connection test for now');

        // Debug: Check authentication status
        final authProvider =
            Provider.of<app_auth.AuthProvider>(context, listen: false);
        debugPrint('User authenticated: ${authProvider.firebaseUser != null}');
        debugPrint('User ID: ${authProvider.firebaseUser?.uid}');
        debugPrint('Number of images to upload: ${_selectedImages.length}');

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Consumer<PropertyProvider>(
            builder: (context, provider, child) {
              final progress = provider.uploadProgress ?? 0.0;
              return AlertDialog(
                title: const Text('Téléchargement des photos...'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 16),
                    Text('${(progress * 100).toInt()}% terminé'),
                    const SizedBox(height: 8),
                    Text('Ne fermez pas cette fenêtre',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              );
            },
          ),
        );
      }

      await propertyProvider.createProperty(property, images: _selectedImages);

      // Close progress dialog if it was shown
      if (_selectedImages.isNotEmpty && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Annonce publiée avec succès !')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la publication: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickLocation() async {
    // TODO: Intègre google_maps_flutter pour un vrai picker
    // Pour l'instant, mock avec Yaoundé
    setState(() {
      _latitudeController.text = '3.8667';
      _longitudeController.text = '11.5167';
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Localisation par défaut (Yaoundé) - Intégrez une carte pour personnaliser')),
      );
    }
  }

  void _focusFirstInvalidFieldOfStep(int step) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (step) {
        case 0:
          if (_titleFieldKey.currentState?.hasError ?? false) {
            Scrollable.ensureVisible(_titleFieldKey.currentContext!,
                duration: const Duration(milliseconds: 300), alignment: 0.2);
            FocusScope.of(context).requestFocus(_titleFocus);
          } else if (_descriptionFieldKey.currentState?.hasError ?? false) {
            Scrollable.ensureVisible(_descriptionFieldKey.currentContext!,
                duration: const Duration(milliseconds: 300), alignment: 0.2);
            FocusScope.of(context).requestFocus(_descriptionFocus);
          } else if (_bedroomsFieldKey.currentState?.hasError ?? false) {
            Scrollable.ensureVisible(_bedroomsFieldKey.currentContext!,
                duration: const Duration(milliseconds: 300), alignment: 0.2);
            FocusScope.of(context).requestFocus(_bedroomsFocus);
          } else if (_bathroomsFieldKey.currentState?.hasError ?? false) {
            Scrollable.ensureVisible(_bathroomsFieldKey.currentContext!,
                duration: const Duration(milliseconds: 300), alignment: 0.2);
            FocusScope.of(context).requestFocus(_bathroomsFocus);
          } else if (_priceFieldKey.currentState?.hasError ?? false) {
            Scrollable.ensureVisible(_priceFieldKey.currentContext!,
                duration: const Duration(milliseconds: 300), alignment: 0.2);
            FocusScope.of(context).requestFocus(_priceFocus);
          } else if (_surfaceFieldKey.currentState?.hasError ?? false) {
            Scrollable.ensureVisible(_surfaceFieldKey.currentContext!,
                duration: const Duration(milliseconds: 300), alignment: 0.2);
            FocusScope.of(context).requestFocus(_surfaceFocus);
          }
          break;
        case 2:
          if (_addressFieldKey.currentState?.hasError ?? false) {
            Scrollable.ensureVisible(_addressFieldKey.currentContext!,
                duration: const Duration(milliseconds: 300), alignment: 0.2);
            FocusScope.of(context).requestFocus(_addressFocus);
          } else if (_districtFieldKey.currentState?.hasError ?? false) {
            Scrollable.ensureVisible(_districtFieldKey.currentContext!,
                duration: const Duration(milliseconds: 300), alignment: 0.2);
            FocusScope.of(context).requestFocus(_districtFocus);
          }
          break;
        default:
          break;
      }
    });
  }

  void _focusFirstFieldOfStep(int step) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (step) {
        case 0:
          // Infos step -> focus title
          if (_titleFieldKey.currentContext != null) {
            Scrollable.ensureVisible(_titleFieldKey.currentContext!,
                duration: const Duration(milliseconds: 300), alignment: 0.2);
          }
          FocusScope.of(context).requestFocus(_titleFocus);
          break;
        case 1:
          // Photos step -> nothing to focus, but ensure Step is visible
          // Try to scroll to the top of the photos section by focusing last known field
          if (_priceFieldKey.currentContext != null) {
            Scrollable.ensureVisible(_priceFieldKey.currentContext!,
                duration: const Duration(milliseconds: 300), alignment: 0.0);
          }
          FocusScope.of(context).unfocus();
          break;
        case 2:
          // Localisation -> focus address
          if (_addressFieldKey.currentContext != null) {
            Scrollable.ensureVisible(_addressFieldKey.currentContext!,
                duration: const Duration(milliseconds: 300), alignment: 0.2);
          }
          FocusScope.of(context).requestFocus(_addressFocus);
          break;
        case 3:
          // Résumé -> scroll to top of resume
          if (_titleFieldKey.currentContext != null) {
            Scrollable.ensureVisible(_titleFieldKey.currentContext!,
                duration: const Duration(milliseconds: 300), alignment: 0.0);
          }
          FocusScope.of(context).unfocus();
          break;
      }
    });
  }

  String? _firstInvalidFieldForStep(int step) {
    switch (step) {
      case 0:
        if (_titleController.text.trim().isEmpty) return 'Titre';
        if (_descriptionController.text.trim().isEmpty) return 'Description';
        final bd = int.tryParse(_bedroomsController.text);
        if (bd == null || bd < 1) return 'Chambres (au moins 1)';
        final ba = int.tryParse(_bathroomsController.text);
        if (ba == null || ba < 1) return 'Salles de bain (au moins 1)';
        final pr = double.tryParse(_priceController.text);
        if (pr == null || pr <= 0) return 'Prix (valeur positive requise)';
        if (_surfaceController.text.isNotEmpty) {
          final su = double.tryParse(_surfaceController.text);
          if (su == null || su <= 0) return 'Superficie (valeur positive)';
        }
        return null;
      case 1:
        // Photos are optional for progressing between steps; enforce at publish time
        return null;
      case 2:
        if (_addressController.text.trim().isEmpty) return 'Adresse';
        if (_districtController.text.trim().isEmpty) return 'Quartier';
        return null;
      default:
        return null;
    }
  }

  List<String> _collectInvalidFields(int step) {
    final issues = <String>[];
    switch (step) {
      case 0:
        if (_titleController.text.trim().isEmpty) issues.add('Titre : requis');
        if (_descriptionController.text.trim().isEmpty) {
          issues.add('Description : requise');
        }
        final bd = int.tryParse(_bedroomsController.text);
        if (bd == null || bd < 1) issues.add('Chambres : entier >= 1');
        final ba = int.tryParse(_bathroomsController.text);
        if (ba == null || ba < 1) issues.add('Salles de bain : entier >= 1');
        final pr = double.tryParse(_priceController.text);
        if (pr == null || pr <= 0) issues.add('Prix : nombre > 0');
        if (_surfaceController.text.isNotEmpty) {
          final su = double.tryParse(_surfaceController.text);
          if (su == null || su <= 0) issues.add('Superficie : nombre > 0');
        }
        break;
      case 1:
        // photos optional for navigation
        break;
      case 2:
        if (_addressController.text.trim().isEmpty) {
          issues.add('Adresse : requise');
        }
        if (_districtController.text.trim().isEmpty) {
          issues.add('Quartier : requis');
        }
        break;
      default:
        break;
    }
    return issues;
  }

  void _handleStepContinue() {
    final formKey = _formKeys[_currentStep];
    final valid = formKey.currentState?.validate() ?? true;

    if (valid) {
      formKey.currentState?.save();
      if (_currentStep < 3) {
        setState(() => _currentStep++);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusFirstFieldOfStep(_currentStep);
        });
      } else {
        _publishProperty();
      }
    } else {
      // Focus the first invalid field and show a clear message
      _focusFirstInvalidFieldOfStep(_currentStep);
      final err = _firstInvalidFieldForStep(_currentStep);
      final all = _collectInvalidFields(_currentStep);
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Champs incorrects'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: all.isNotEmpty
                    ? all.map((s) => Text('• $s')).toList()
                    : [
                        Text(err ??
                            'Veuillez compléter ou corriger les champs requis.')
                      ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer une Annonce'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Theme(
            data: Theme.of(context).copyWith(
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Stepper(
                  currentStep: _currentStep,
                  onStepContinue: _handleStepContinue,
                  onStepCancel: _currentStep > 0
                      ? () => setState(() => _currentStep--)
                      : null,
                  onStepTapped: (index) {
                    if (index <= _currentStep) {
                      setState(() => _currentStep = index);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _focusFirstFieldOfStep(_currentStep);
                      });
                    }
                  },
                  controlsBuilder: (context, details) {
                    final isLastStep = _currentStep == 3;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentStep > 0)
                            Flexible(
                              child: TextButton(
                                onPressed: details.onStepCancel,
                                child: const Text('Retour'),
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                          Flexible(
                            child: ElevatedButton(
                              onPressed: _handleStepContinue,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(100, 40),
                              ),
                              child: Text(isLastStep ? 'Publier' : 'Suivant'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  steps: [
                    Step(
                      title: const Text('Informations'),
                      content: Form(
                        key: _formKeys[0],
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: _buildInfosStep(),
                      ),
                      isActive: _currentStep >= 0,
                      state: _currentStep > 0
                          ? StepState.complete
                          : StepState.editing,
                    ),
                    // STEP 2: PHOTOS
                    Step(
                      title: const Text('Photos'),
                      content: Form(
                        key: _formKeys[1],
                        child: _buildPhotosStep(),
                      ),
                      isActive: _currentStep >= 1,
                      state: _selectedImages.isNotEmpty
                          ? StepState.complete
                          : StepState.editing,
                    ),
                    // STEP 3: LOCALISATION
                    Step(
                      title: const Text('Localisation'),
                      content: Form(
                        key: _formKeys[2],
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: _buildLocalisationStep(),
                      ),
                      isActive: _currentStep >= 2,
                      state: _currentStep > 2
                          ? StepState.complete
                          : StepState.editing,
                    ),
                    // STEP 4: RÉSUMÉ
                    Step(
                      title: const Text('Résumé'),
                      content: Form(
                        key: _formKeys[3],
                        child: _buildResumeStep(),
                      ),
                      isActive: _currentStep >= 3,
                      state: StepState.editing,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfosStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            key: _titleFieldKey,
            focusNode: _titleFocus,
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Titre de l\'annonce',
              hintText: 'ex: Bel appartement 2 chambres',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            validator: (value) =>
                (value ?? '').isEmpty ? 'Le titre est requis' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: _descriptionFieldKey,
            focusNode: _descriptionFocus,
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Décrivez votre propriété...',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            maxLines: 4,
            validator: (value) =>
                (value ?? '').isEmpty ? 'La description est requise' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _propertyType,
            decoration: InputDecoration(
              labelText: 'Type de propriété',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: const [
              DropdownMenuItem(value: 'apartment', child: Text('Appartement')),
              DropdownMenuItem(value: 'house', child: Text('Maison')),
              DropdownMenuItem(value: 'studio', child: Text('Studio')),
              DropdownMenuItem(value: 'room', child: Text('Chambre')),
              DropdownMenuItem(value: 'office', child: Text('Bureau')),
            ],
            onChanged: (value) =>
                setState(() => _propertyType = value ?? 'apartment'),
          ),
          const SizedBox(height: 12),
          // Listing purpose: rent or sale
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Type d\'annonce: ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ChoiceChip(
                label: const Text('Location'),
                selected: _listingPurpose == 'rent',
                onSelected: (s) => setState(() => _listingPurpose = 'rent'),
              ),
              ChoiceChip(
                label: const Text('Vente'),
                selected: _listingPurpose == 'sale',
                onSelected: (s) => setState(() => _listingPurpose = 'sale'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Style dropdown for studio/apartment
          if (_propertyType == 'studio') ...[
            DropdownButtonFormField<String>(
              initialValue: _style,
              decoration: InputDecoration(
                labelText: 'Style du studio',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: const [
                DropdownMenuItem(value: 'simple', child: Text('Simple')),
                DropdownMenuItem(value: 'modern', child: Text('Modern')),
              ],
              onChanged: (v) => setState(() => _style = v ?? 'simple'),
            ),
            const SizedBox(height: 16),
          ] else if (_propertyType == 'apartment') ...[
            DropdownButtonFormField<String>(
              initialValue: _style,
              decoration: InputDecoration(
                labelText: 'Style de l\'appartement',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: const [
                DropdownMenuItem(value: 'simple', child: Text('Simple')),
                DropdownMenuItem(value: 'meuble', child: Text('Meublé')),
                DropdownMenuItem(
                    value: 'haut_standing', child: Text('Haut standing')),
              ],
              onChanged: (v) => setState(() => _style = v ?? 'simple'),
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: _bedroomsFieldKey,
                  focusNode: _bedroomsFocus,
                  controller: _bedroomsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Chambres',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Au moins 1 chambre requise';
                    }
                    final parsed = int.tryParse(value.trim());
                    if (parsed == null || parsed < 1) {
                      return 'Au moins 1 chambre (nombre entier positif)';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  key: _bathroomsFieldKey,
                  focusNode: _bathroomsFocus,
                  controller: _bathroomsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Salles de bain',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Au moins 1 salle de bain requise';
                    }
                    final parsed = int.tryParse(value.trim());
                    if (parsed == null || parsed < 1) {
                      return 'Au moins 1 salle de bain (nombre entier positif)';
                    }
                    return null;
                  },
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
                  key: _priceFieldKey,
                  focusNode: _priceFocus,
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Prix',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Prix requis';
                    }
                    final parsed = double.tryParse(value.trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Prix valide requis (nombre positif)';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _currency,
                  decoration: InputDecoration(
                    labelText: 'Devise',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'XAF', child: Text('XAF')),
                    DropdownMenuItem(value: 'USD', child: Text('USD')),
                    DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                  ],
                  onChanged: (value) =>
                      setState(() => _currency = value ?? 'XAF'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: _surfaceFieldKey,
                  focusNode: _surfaceFocus,
                  controller: _surfaceController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Superficie (m²)',
                    hintText: 'ex: 65',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return null; // Optionnel
                    }
                    final parsed = double.tryParse(value.trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Superficie valide requise (nombre positif)';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Balconies, lease duration, deposit, power & water (conditional)
          if (_propertyType == 'apartment' || _listingPurpose == 'rent') ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _balconiesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Balcons',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _leaseMonthsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Durée min (mois)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _depositController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Montant caution',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _powerType,
                    decoration: InputDecoration(
                      labelText: 'Type de courant',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'normal', child: Text('Compteur normal')),
                      DropdownMenuItem(
                          value: 'prepaid', child: Text('Compteur prépayé')),
                    ],
                    onChanged: (v) =>
                        setState(() => _powerType = v ?? 'normal'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _waterSupplier,
              decoration: InputDecoration(
                labelText: 'Fournisseur d\'eau',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: const [
                DropdownMenuItem(value: 'camwater', child: Text('Camwater')),
                DropdownMenuItem(value: 'forage', child: Text('Forage')),
                DropdownMenuItem(value: 'other', child: Text('Autre')),
              ],
              onChanged: (v) =>
                  setState(() => _waterSupplier = v ?? 'camwater'),
            ),
            const SizedBox(height: 12),
          ],

          // For meublé style, show furnished-specific options
          if (_style == 'meuble') ...[
            DropdownButtonFormField<String>(
              initialValue: _furnishedPeriodUnit,
              decoration: InputDecoration(
                labelText: 'Période meublé',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: const [
                DropdownMenuItem(value: 'day', child: Text('Jour')),
                DropdownMenuItem(value: 'week', child: Text('Semaine')),
                DropdownMenuItem(value: 'month', child: Text('Mois')),
                DropdownMenuItem(value: 'year', child: Text('Année')),
              ],
              onChanged: (v) =>
                  setState(() => _furnishedPeriodUnit = v ?? 'month'),
            ),
            CheckboxListTile(
              title: const Text('Pas de caution pour meublé'),
              value: _furnishedNoDeposit,
              onChanged: (v) =>
                  setState(() => _furnishedNoDeposit = v ?? false),
            ),
            const SizedBox(height: 12),
          ],
          // Amenities (bonus: checkboxes)
          const SizedBox(height: 16),
          const Text('Équipements:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: ['wifi', 'parking', 'pool', 'ac', 'kitchen']
                .map((amenity) => CheckboxListTile(
                      title: Text(amenity.toUpperCase()),
                      value: _selectedAmenities.contains(amenity),
                      onChanged: (bool? checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedAmenities.add(amenity);
                          } else {
                            _selectedAmenities.remove(amenity);
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _pickImages,
            icon: const Icon(Icons.add_photo_alternate),
            label: Text('Ajouter des photos (${_selectedImages.length}/10)'),
          ),
          const SizedBox(height: 24),
          if (_selectedImages.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(Icons.image, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Aucune photo sélectionnée',
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            )
          else ...[
            // Removed Consumer to avoid provider errors; progress can be handled during upload in step 3
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: kIsWeb
                          ? Image.network(
                              _selectedImages[index].path,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child:
                                      const Icon(Icons.broken_image, size: 50),
                                );
                              },
                            )
                          : Image.file(
                              File(_selectedImages[index].path),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child:
                                      const Icon(Icons.broken_image, size: 50),
                                );
                              },
                            ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocalisationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextFormField(
            key: _addressFieldKey,
            focusNode: _addressFocus,
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Adresse',
              hintText: 'ex: Rue Principale, n°123',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            validator: (value) =>
                (value ?? '').isEmpty ? 'L\'adresse est requise' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: _districtFieldKey,
            focusNode: _districtFocus,
            controller: _districtController,
            decoration: InputDecoration(
              labelText: 'Quartier/Arrondissement',
              hintText: 'ex: Bastos, Mimboman',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            validator: (value) =>
                (value ?? '').isEmpty ? 'Le quartier est requis' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _latitudeController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Latitude (optionnel)',
                    hintText: 'ex: 3.8667',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _longitudeController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Longitude (optionnel)',
                    hintText: 'ex: 11.5167',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _pickLocation,
            icon: const Icon(Icons.location_on),
            label: const Text('Choisir sur Carte'),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
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
                _resumeItem('Type', _propertyType.toUpperCase()),
                _resumeItem('Chambres', _bedroomsController.text),
                _resumeItem('Salles de bain', _bathroomsController.text),
                _resumeItem(
                    'Superficie (m²)',
                    _surfaceController.text.isEmpty
                        ? 'Non spécifié'
                        : '${_surfaceController.text} m²'),
                _resumeItem('Prix', '${_priceController.text} $_currency'),
                _resumeItem('Type d\'annonce', _listingPurpose.toUpperCase()),
                if (_style.isNotEmpty) _resumeItem('Style', _style),
                if ((_balconiesController.text).isNotEmpty)
                  _resumeItem('Balcons', _balconiesController.text),
                if ((_leaseMonthsController.text).isNotEmpty)
                  _resumeItem('Durée min (mois)', _leaseMonthsController.text),
                if ((_depositController.text).isNotEmpty)
                  _resumeItem(
                      'Caution', '${_depositController.text} $_currency'),
                _resumeItem('Type courant', _powerType),
                _resumeItem('Fournisseur eau', _waterSupplier),
                _resumeItem('Adresse', _addressController.text),
                _resumeItem('Quartier', _districtController.text),
                _resumeItem('Photos', '${_selectedImages.length} photo(s)'),
                if (_selectedAmenities.isNotEmpty)
                  _resumeItem('Équipements', _selectedAmenities.join(', ')),
                _resumeItem(
                    'Conditions',
                    _conditionsController.text.isEmpty
                        ? 'Aucune'
                        : _conditionsController.text),
              ],
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _conditionsController,
            decoration: InputDecoration(
              labelText: 'Conditions spéciales (optionnel)',
              hintText: 'ex: Pas d\'animaux, caution requise',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Publication en cours...'),
              ],
            )
          else
            ElevatedButton(
              onPressed: _publishProperty,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Publier l\'annonce',
                  style: TextStyle(fontSize: 16)),
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
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value.isEmpty ? 'Non spécifié' : value,
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
