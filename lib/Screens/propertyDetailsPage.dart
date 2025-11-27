import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rent_house/Models/property.dart';
import 'package:rent_house/Providers/property_provider.dart';
import 'package:rent_house/Providers/auth_provider.dart' as app_auth;
import 'package:rent_house/Screens/editPropertyPage.dart';
import 'package:rent_house/Models/booking.dart';
import 'package:rent_house/Providers/booking_provider.dart';
import 'package:share_plus/share_plus.dart';
// BookingService not required here since payments are off-platform

class PropertyDetailsPage extends StatefulWidget {
  static const String routeName = '/propertyDetailsRoute';
  final Property property;

  const PropertyDetailsPage({super.key, required this.property});

  @override
  State<PropertyDetailsPage> createState() => _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends State<PropertyDetailsPage> {
  bool _isFavorite = false;
  late final PageController _imagePageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    // Capture provider outside the post frame callback to avoid using
    // BuildContext across async gaps (analyzer warning).
    final initialProvider =
        Provider.of<PropertyProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final favs = initialProvider.favorites;
      if (favs != null) {
        setState(() {
          _isFavorite = favs.any((p) => p.id == widget.property.id);
        });
      }
    });
    _imagePageController = PageController();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    final propertyProvider =
        Provider.of<PropertyProvider>(context, listen: false);
    try {
      final changed = await propertyProvider.toggleFavorite(widget.property);
      if (changed) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
      }
    } catch (e) {
      debugPrint('Erreur toggle favorite: $e');
    }
  }

  Future<void> _shareProperty() async {
    try {
      final property = widget.property;
      // Créer un lien partageable (deep link ou lien web)
      final propertyLink = 'https://allobailleur.app/property/${property.id}';

      final shareText = '''
🏠 ${property.title}

📍 ${property.city}, ${property.district ?? property.country}
💰 ${property.price.toStringAsFixed(0)} ${property.currency}/mois
🏠 ${property.bedrooms} ch. • 🛁 ${property.bathrooms} sdb • 📐 ${property.surface?.toInt() ?? 0} m²

${property.description}

🔗 Voir l'annonce complète : $propertyLink

Découvrez cette propriété sur Allô Bailleur !
#AlloBailleur #Location #${property.city}
      '''
          .trim();

      await Share.share(
        shareText,
        subject: 'Découvrez cette propriété : ${property.title}',
      );
    } catch (e) {
      debugPrint('Erreur lors du partage: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du partage')),
        );
      }
    }
  }

  Widget _featureChip(IconData icon, String label) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(label)
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayCurrency =
        widget.property.currency.isNotEmpty ? widget.property.currency : 'XAF';
    final authProvider =
        Provider.of<app_auth.AuthProvider>(context, listen: false);
    final currentUid = authProvider.firebaseUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.property.title),
        actions: [
          // Show edit button to owner (use build context's provider)
          if (currentUid != null && currentUid == widget.property.ownerId)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                // Capture navigator and provider before awaiting to avoid
                // using BuildContext across async gaps.
                final navigator = Navigator.of(context);
                final provider =
                    Provider.of<PropertyProvider>(context, listen: false);
                await navigator.push(MaterialPageRoute(
                  builder: (_) => EditPropertyPage(property: widget.property),
                ));
                if (!mounted) return;
                await provider.fetchProperties();
                await provider.loadHostProperties(currentUid);
              },
            ),
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareProperty,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.property.imageUrls.isNotEmpty)
              Column(
                children: [
                  SizedBox(
                    height: 260,
                    child: PageView.builder(
                      controller: _imagePageController,
                      itemCount: widget.property.imageUrls.length,
                      onPageChanged: (i) =>
                          setState(() => _currentImageIndex = i),
                      itemBuilder: (context, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.property.imageUrls[i],
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    ),
                  ),
                  if (widget.property.imageUrls.length > 1)
                    SizedBox(
                      height: 88,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        itemCount: widget.property.imageUrls.length,
                        itemBuilder: (context, i) {
                          final url = widget.property.imageUrls[i];
                          return GestureDetector(
                            onTap: () => _imagePageController.animateToPage(i,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              width: 110,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: i == _currentImageIndex
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(url, fit: BoxFit.cover),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              )
            else
              Container(height: 220, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              '${widget.property.price.toStringAsFixed(0)} $displayCurrency/mois',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
                '${widget.property.address ?? ''} • ${widget.property.city}, ${widget.property.country}'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _featureChip(Icons.bed, '${widget.property.bedrooms} chambres'),
                _featureChip(
                    Icons.bathroom, '${widget.property.bathrooms} sdb'),
                _featureChip(
                    Icons.square_foot, '${widget.property.surface ?? 0} m²'),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Description',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.property.description),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => BookingPage(property: widget.property),
              ));
            },
            child: const Text('Réserver'),
          ),
        ),
      ),
    );
  }
}

class BookingPage extends StatefulWidget {
  static const String routeName = '/booking';
  final Property property;

  const BookingPage({super.key, required this.property});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = picked;
          if (_checkOutDate != null && _checkOutDate!.isBefore(picked)) {
            _checkOutDate = null;
          }
        } else {
          _checkOutDate = picked;
        }
      });
    }
  }

  Future<void> _confirmBooking() async {
    if (_checkInDate == null || _checkOutDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Veuillez sélectionner les dates')));
      }
      return;
    }
    if (_checkOutDate!.isBefore(_checkInDate!)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Date de départ invalide')));
      }
      return;
    }

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final nights = _checkOutDate!.difference(_checkInDate!).inDays;
      final property = widget.property; // capture widget values before awaits
      final totalPrice = nights > 0 ? property.price * nights : 0.0;
      // Paiement des locations géré hors-plateforme. PlatformFee = 0.

      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      final authProvider =
          Provider.of<app_auth.AuthProvider>(context, listen: false);
      final guestId = authProvider.firebaseUser?.uid ?? '';

      final booking = Booking(
        id: '',
        guestId: guestId,
        propertyId: property.id,
        hostId: property.ownerId,
        checkInDate: _checkInDate!,
        checkOutDate: _checkOutDate!,
        totalPrice: totalPrice.toDouble(),
        // Sur la plateforme, nous ne prenons pas de commission sur le montant
        // de la location. platformFee = 0, hostPayout = totalPrice.
        platformFee: 0.0,
        hostPayout: totalPrice.toDouble(),
        status: 'pending', // Statut pending — l'hôte confirmera la réservation
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Capture propertyProvider before awaiting any async operations
      // to avoid using BuildContext across async gaps.
      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);

      final created = await bookingProvider.createBooking(booking);
      if (!created) {
        if (mounted) {
          messenger.showSnackBar(SnackBar(
              content: Text('Erreur: ${bookingProvider.errorMessage ?? ''}')));
        }
        return;
      }

      // Pas de paiement via la plateforme pour la location —
      // l'hôte et le client finalisent le paiement hors-plateforme.
      await propertyProvider.completeRental(property);

      if (mounted) {
        messenger.showSnackBar(
            const SnackBar(content: Text('Réservation confirmée')));
        navigator.popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Erreur: $e')));
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
      appBar: AppBar(title: const Text('Réserver')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: const Text('Date d\'arrivée'),
              subtitle: Text(_checkInDate?.toLocal().toString().split(' ')[0] ??
                  'Sélectionner'),
              trailing: ElevatedButton(
                  onPressed: () => _selectDate(context, true),
                  child: const Text('Choisir')),
            ),
            ListTile(
              title: const Text('Date de départ'),
              subtitle: Text(
                  _checkOutDate?.toLocal().toString().split(' ')[0] ??
                      'Sélectionner'),
              trailing: ElevatedButton(
                  onPressed: () => _selectDate(context, false),
                  child: const Text('Choisir')),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
                onPressed: _isLoading ? null : _confirmBooking,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Confirmer la réservation')),
          ],
        ),
      ),
    );
  }
}
