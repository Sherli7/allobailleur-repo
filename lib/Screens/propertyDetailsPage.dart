import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rent_house/Models/property.dart';
import 'package:rent_house/Providers/property_provider.dart';
import 'package:rent_house/Providers/auth_provider.dart' as app_auth;
import 'package:rent_house/Providers/review_provider.dart';
import 'package:rent_house/Screens/editPropertyPage.dart';
import 'package:rent_house/Screens/bookPostingPage.dart';
import 'package:share_plus/share_plus.dart';
import 'package:rent_house/Services/messages_service.dart';
import 'package:rent_house/Screens/conversation_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rent_house/l10n/app_localizations.dart'; // Localization

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
    final initialProvider =
        Provider.of<PropertyProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final favs = initialProvider.favorites;
      if (favs != null) {
        setState(() {
          _isFavorite = favs.any((p) => p.id == widget.property.id);
        });
      }
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
    setState(() {
      _isFavorite = !_isFavorite;
    });
    try {
      final changed = await propertyProvider.toggleFavorite(widget.property);
      if (!changed) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
      }
    } catch (e) {
      setState(() {
        _isFavorite = !_isFavorite;
      });
      debugPrint('Erreur toggle favorite: $e');
    }
  }

  Future<void> _shareProperty() async {
    try {
      final property = widget.property;
      final propertyLink = 'https://allobailleur.app/property/${property.id}';
      // Note: Localization for share text inside function might be tricky without context if async gap
      // But here we are in State, so 'context' is available (check mounted).
      // For simplicity, we keep hardcoded or minimal text here or use context.

      final shareText = '''
🏠 ${property.title}

📍 ${property.city}, ${property.district ?? property.country}
💰 ${property.price.toStringAsFixed(0)} ${property.currency}/mois

${property.description}

🔗 $propertyLink
      '''
          .trim();

      await Share.share(
        shareText,
        subject: property.title,
      );
    } catch (e) {
      debugPrint('Erreur lors du partage: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context)?.shareError ?? 'Error sharing')),
        );
      }
    }
  }

  Future<void> _handleMessageButton() async {
    final l10n = AppLocalizations.of(context);
    // Supabase Auth check
    final supabaseUser = Supabase.instance.client.auth.currentUser;

    if (supabaseUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez vous connecter pour envoyer un message.')),
      );
      Navigator.of(context).pushNamed('/login');
      return;
    }

    if (supabaseUser.id == widget.property.ownerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(l10n?.selfMessageError ?? 'You cannot message yourself.')),
      );
      return;
    }

    setState(() => _isMessageLoading = true);
    try {
      final conversationId = await MessagesService()
          .getOrCreateConversation(widget.property.ownerId, widget.property.id);

      if (!mounted) return;

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
          SnackBar(content: Text('${l10n?.conversationError ?? "Error"}: $e')),
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
    final l10n = AppLocalizations.of(context);
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n?.reviews ?? 'Avis',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => _showAddReviewDialog(context),
                  child: Text(l10n?.addReview ?? 'Ajouter un avis'),
                ),
              ],
            ),
            if (reviewProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (reviewProvider.reviews.isEmpty)
              Text(l10n?.noReviewsYet ?? 'Aucun avis.')
            else
              Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      Text(
                          '${reviewProvider.averageRating.toStringAsFixed(1)} (${reviewProvider.reviews.length})'),
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
    final l10n = AppLocalizations.of(context);
    final displayCurrency =
        widget.property.currency.isNotEmpty ? widget.property.currency : 'XAF';

    final currentUid = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.property.title),
        actions: [
          if (currentUid != null && currentUid == widget.property.ownerId)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final navigator = Navigator.of(context);
                final provider =
                    Provider.of<PropertyProvider>(context, listen: false);
                await navigator.push(MaterialPageRoute(
                  builder: (_) => EditPropertyPage(property: widget.property),
                ));
                if (!mounted) return;
                await provider.fetchProperties();
                if (currentUid != null) {
                  await provider.loadHostProperties(currentUid);
                }
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
                _featureChip(Icons.bed,
                    '${widget.property.bedrooms} ${l10n?.bedrooms ?? "chambres"}'),
                _featureChip(Icons.bathroom,
                    '${widget.property.bathrooms} ${l10n?.bathrooms ?? "sdb"}'),
                _featureChip(
                    Icons.square_foot, '${widget.property.surface ?? 0} m²'),
              ],
            ),
            const SizedBox(height: 16),
            Text(l10n?.description ?? 'Description',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.chat_bubble_outline),
                  onPressed: _isMessageLoading ? null : _handleMessageButton,
                  label: Text(l10n?.sendMessage ?? 'Message'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final user = Supabase.instance.client.auth.currentUser;
                    if (user == null) {
                      Navigator.of(context).pushNamed('/login');
                    } else {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            BookPostingPage(property: widget.property),
                      ));
                    }
                  },
                  child: Text(l10n?.book ?? 'Réserver'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
