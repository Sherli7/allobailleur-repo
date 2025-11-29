import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rent_house/Models/property.dart';
import 'package:rent_house/Providers/property_provider.dart';
import 'package:rent_house/Providers/auth_provider.dart' as app_auth;
import 'package:rent_house/Providers/review_provider.dart';
import 'package:rent_house/Screens/editPropertyPage.dart';
import 'package:rent_house/Screens/bookingsPage.dart';
import 'package:share_plus/share_plus.dart';
import 'package:rent_house/Services/messages_service.dart';
import 'package:rent_house/Screens/conversation_page.dart';

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
  bool _isMessageLoading = false;

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
      // Load reviews
      context.read<ReviewProvider>().loadReviews(widget.property.id);
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
    // Optimistic update: toggle immediately for better UX
    setState(() {
      _isFavorite = !_isFavorite;
    });
    try {
      final changed = await propertyProvider.toggleFavorite(widget.property);
      if (!changed) {
        // Revert if failed
        setState(() {
          _isFavorite = !_isFavorite;
        });
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _isFavorite = !_isFavorite;
      });
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

  Future<void> _handleMessageButton() async {
    final user = Provider.of<app_auth.AuthProvider>(context, listen: false)
        .firebaseUser;
    
    if (user == null) {
      Navigator.of(context).pushNamed('/login');
      return;
    }

    if (user.uid == widget.property.ownerId) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vous ne pouvez pas vous envoyer de message à vous-même.')),
       );
       return;
    }

    setState(() => _isMessageLoading = true);
    try {
      // Récupérer ou créer la conversation
      final conversationId = await MessagesService()
          .getOrCreateConversation(widget.property.ownerId, widget.property.id);
      
      if (!mounted) return;
      
      // Naviguer vers la page de conversation
      Navigator.of(context).pushNamed(
        ConversationPage.routeName,
        arguments: {
          'conversationId': conversationId,
          'property': widget.property,
        },
      );
    } catch (e) {
      debugPrint('Erreur création conversation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de démarrer la conversation')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isMessageLoading = false);
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

  Widget _buildReviewsSection() {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Avis',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => _showAddReviewDialog(context),
                  child: const Text('Ajouter un avis'),
                ),
              ],
            ),
            if (reviewProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (reviewProvider.reviews.isEmpty)
              const Text('Aucun avis pour le moment.')
            else
              Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      Text(
                          '${reviewProvider.averageRating.toStringAsFixed(1)} (${reviewProvider.reviews.length} avis)'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...reviewProvider.reviews.map((review) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(review.userName ?? 'Anonyme',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  ...List.generate(
                                      5,
                                      (i) => Icon(
                                            i < review.rating
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: Colors.amber,
                                            size: 16,
                                          )),
                                ],
                              ),
                              if (review.comment != null) ...[
                                const SizedBox(height: 8),
                                Text(review.comment!),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
              ),
          ],
        );
      },
    );
  }

  void _showAddReviewDialog(BuildContext context) {
    double rating = 5.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Ajouter un avis'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Note:'),
              Slider(
                value: rating,
                min: 1,
                max: 5,
                divisions: 4,
                label: rating.toString(),
                onChanged: (value) => setState(() => rating = value),
              ),
              TextField(
                controller: commentController,
                decoration:
                    const InputDecoration(labelText: 'Commentaire (optionnel)'),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                final success = await context.read<ReviewProvider>().addReview(
                      widget.property.id,
                      rating,
                      commentController.text.isEmpty
                          ? null
                          : commentController.text,
                    );
                Navigator.of(context).pop();
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Avis ajouté avec succès')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Erreur lors de l\'ajout de l\'avis')),
                  );
                }
              },
              child: const Text('Ajouter'),
            ),
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
                  Hero(
                    tag: 'property-${widget.property.id}',
                    child: SizedBox(
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
            const SizedBox(height: 16),
            _buildReviewsSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: _isMessageLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : const Icon(Icons.chat_bubble_outline),
                  onPressed: _isMessageLoading ? null : _handleMessageButton,
                  label: const Text('Message'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final user =
                        Provider.of<app_auth.AuthProvider>(context, listen: false)
                            .firebaseUser;
                    if (user == null) {
                      Navigator.of(context).pushNamed('/login');
                    } else {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => BookingPage(property: widget.property),
                      ));
                    }
                  },
                  child: const Text('Réserver'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
