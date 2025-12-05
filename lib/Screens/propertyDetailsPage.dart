// lib/Screens/property_details_page.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';
import 'package:rent_house/Models/property.dart';
import 'package:rent_house/Providers/property_provider.dart';
import 'package:rent_house/Providers/review_provider.dart';
import 'package:rent_house/Screens/book_posting_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:rent_house/Services/messages_service.dart';
import 'package:rent_house/Screens/conversation_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'editPropertyPage.dart';

class PropertyDetailsPage extends StatefulWidget {
  static const String routeName = '/property-details';
  final Property property;

  const PropertyDetailsPage({super.key, required this.property});

  @override
  State<PropertyDetailsPage> createState() => _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends State<PropertyDetailsPage> {
  bool _isFavorite = false;
  int _currentImageIndex = 0;
  bool _isMessageLoading = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PropertyProvider>();
      _isFavorite = provider.favorites.any((p) => p.id == widget.property.id);
      context.read<ReviewProvider>().loadReviews(widget.property.id);
    });
  }

  Future<void> _toggleFavorite() async {
    final provider = context.read<PropertyProvider>();
    setState(() => _isFavorite = !_isFavorite);
    final success = await provider.toggleFavorite(widget.property);
    if (!success) setState(() => _isFavorite = !_isFavorite);
  }

  Future<void> _shareProperty() async {
    final link = 'https://allobailleur.app/property/${widget.property.id}';
    final text =
        '''
🏠 ${widget.property.title}

📍 ${widget.property.city}, ${widget.property.address ?? widget.property.district ?? ''}
💰 ${widget.property.price.toInt()} ${widget.property.currency}/mois

${widget.property.description ?? ''}

🔗 $link
    '''
            .trim();

    await Share.share(text, subject: widget.property.title);
  }

  Future<void> _handleMessage() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }
    if (user.id == widget.property.ownerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vous ne pouvez pas vous envoyer un message"),
        ),
      );
      return;
    }

    setState(() => _isMessageLoading = true);
    try {
      final convId = await MessagesService().getOrCreateConversation(
        widget.property.ownerId,
        widget.property.id,
      );
      if (mounted) {
        Navigator.pushNamed(
          context,
          ConversationPage.routeName,
          arguments: {'conversationId': convId, 'property': widget.property},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _isMessageLoading = false);
    }
  }

  void _openPhotoGallery(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withAlpha(242), // Replace withOpacity(0.95)
        pageBuilder: (_, __, ___) => PhotoViewGallery.builder(
          scrollPhysics: const BouncingScrollPhysics(),
          builder: (context, index) {
            return PhotoViewGalleryPageOptions(
              imageProvider: NetworkImage(widget.property.imageUrls[index]),
              initialScale: PhotoViewComputedScale.contained,
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 4,
              heroAttributes: PhotoViewHeroAttributes(
                tag: 'photo-$index-${widget.property.id}',
              ),
            );
          },
          itemCount: widget.property.imageUrls.length,
          loadingBuilder: (context, event) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          pageController: PageController(initialPage: initialIndex),
          onPageChanged: (index) => setState(() => _currentImageIndex = index),
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _openMap() async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${widget.property.latitude},${widget.property.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _showAddReviewDialog() {
    double rating = 5.0;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Votre avis"),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Note : ${rating.toInt()} étoile${rating > 1 ? 's' : ''}"),
              Slider(
                value: rating,
                min: 1,
                max: 5,
                divisions: 4,
                onChanged: (v) => setState(() => rating = v),
              ),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: "Commentaire (facultatif)",
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await context.read<ReviewProvider>().addReview(
                widget.property.id,
                rating.toInt() as double,
                controller.text.isEmpty ? null : controller.text,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(success ? "Avis ajouté !" : "Erreur")),
              );
            },
            child: const Text("Envoyer"),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      backgroundColor: Colors.grey[100],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final isOwner = userId == widget.property.ownerId;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.property.title),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                setState(() => _isLoading = true);
                await Navigator.pushNamed(
                  context,
                  EditPropertyPage.routeName,
                  arguments: widget.property,
                );
                if (mounted) {
                  await context.read<PropertyProvider>().loadPropertiesOnce();
                  setState(() => _isLoading = false);
                }
              },
            ),
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            color: _isFavorite ? Colors.red : null,
            onPressed: _toggleFavorite,
          ),
          IconButton(icon: const Icon(Icons.share), onPressed: _shareProperty),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === GALERIE ZOOMABLE ===
                  if (widget.property.imageUrls.isNotEmpty)
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () =>
                              _openPhotoGallery(context, _currentImageIndex),
                          child: Hero(
                            tag:
                                'photo-$_currentImageIndex-${widget.property.id}',
                            child: SizedBox(
                              height: 320,
                              width: double.infinity,
                              child: CachedNetworkImage(
                                imageUrl: widget
                                    .property
                                    .imageUrls[_currentImageIndex],
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Miniatures
                        if (widget.property.imageUrls.length > 1)
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.all(8),
                              itemCount: widget.property.imageUrls.length,
                              itemBuilder: (context, i) => GestureDetector(
                                onTap: () {
                                  setState(() => _currentImageIndex = i);
                                  _openPhotoGallery(context, i);
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: i == _currentImageIndex
                                          ? Colors.blue
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                  child: Hero(
                                    tag: 'photo-$i-${widget.property.id}',
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: CachedNetworkImage(
                                        imageUrl: widget.property.imageUrls[i],
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  else
                    Container(
                      height: 320,
                      color: Colors.grey[300],
                      child: const Icon(Icons.home, size: 80),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Prix & Titre
                        Text(
                          '${widget.property.price.toInt()} ${widget.property.currency}/mois',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.property.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _openMap,
                          child: Text(
                            '${widget.property.city} • ${widget.property.address ?? widget.property.district ?? ''}',
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        if (widget.property.distance != null)
                          Text(
                            '${widget.property.distance!.toStringAsFixed(1)} km de vous',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(height: 20),

                        // Caractéristiques
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _buildFeatureChip(
                              Icons.king_bed,
                              '${widget.property.rooms ?? 0} chambre${widget.property.rooms == 1 ? '' : 's'}', // Fix string formatting
                            ),
                            _buildFeatureChip(
                              Icons.bathtub,
                              '${widget.property.bathrooms ?? 0} sdb',
                            ),
                            if (widget.property.surface != null)
                              _buildFeatureChip(
                                Icons.square_foot,
                                '${widget.property.surface!.toInt()} m²',
                              ),
                            if (widget.property.balconies != null &&
                                widget.property.balconies! > 0)
                              _buildFeatureChip(
                                Icons.balcony,
                                '${widget.property.balconies} balcon${widget.property.balconies! > 1 ? 's' : ''}',
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Description
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.property.description ?? 'Aucune description.',
                          style: const TextStyle(height: 1.5),
                        ),

                        const SizedBox(height: 24),

                        // Avis
                        Consumer<ReviewProvider>(
                          builder: (context, rp, child) {
                            if (rp.isLoading)
                              return const CircularProgressIndicator();
                            if (rp.reviews.isEmpty) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Avis',
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: _showAddReviewDialog,
                                    child: const Text(
                                      'Soyez le premier à laisser un avis',
                                    ),
                                  ),
                                ],
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Avis • ${rp.averageRating.toStringAsFixed(1)} ⭐',
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _showAddReviewDialog,
                                      child: const Text('Ajouter'),
                                    ),
                                  ],
                                ),
                                ...rp.reviews
                                    .take(3)
                                    .map(
                                      (r) => Card(
                                        child: ListTile(
                                          leading: const CircleAvatar(
                                            child: Icon(Icons.person),
                                          ),
                                          title: Text(r.userName ?? 'Anonyme'),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: List.generate(
                                                  5,
                                                  (i) => Icon(
                                                    i < r.rating
                                                        ? Icons.star
                                                        : Icons.star_border,
                                                    color: Colors.amber,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                              if (r.comment != null)
                                                Text(r.comment!),
                                            ],
                                          ),
                                          trailing: Text(
                                            r.createdAt.toString().split(
                                              ' ',
                                            )[0],
                                          ),
                                        ),
                                      ),
                                    ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

      // === BOTTOM BAR ===
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: _isMessageLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.message),
                  label: const Text('Message'),
                  onPressed: _isMessageLoading ? null : _handleMessage,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Réserver'),
                  onPressed: () {
                    final user = Supabase.instance.client.auth.currentUser;
                    if (user == null) {
                      Navigator.pushNamed(context, '/login');
                    } else {
                      Navigator.pushNamed(
                        context,
                        BookPostingPage.routeName,
                        arguments: widget.property,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
