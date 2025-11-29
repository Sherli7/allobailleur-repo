import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Models/review.dart';

class ReviewProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Review> _reviews = [];
  bool _isLoading = false;

  List<Review> get reviews => _reviews;
  bool get isLoading => _isLoading;

  Future<void> loadReviews(String propertyId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('reviews')
          .select('*, users(firstName, lastName)')
          .eq('propertyId', propertyId)
          .order('createdAt', ascending: false);

      _reviews = (response as List).map((json) {
        final user = json['users'];
        final userName = user != null
            ? '${user['firstName']} ${user['lastName']}'
            : 'Anonyme';
        return Review.fromJson({...json, 'userName': userName});
      }).toList();
    } catch (e) {
      debugPrint('Error loading reviews: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addReview(
      String propertyId, double rating, String? comment) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final response = await _supabase.from('reviews').insert({
        'propertyId': propertyId,
        'userId': userId,
        'rating': rating,
        'comment': comment,
      }).select();

      if (response.isNotEmpty) {
        await loadReviews(propertyId); // Reload reviews
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding review: $e');
      return false;
    }
  }

  double get averageRating {
    if (_reviews.isEmpty) return 0;
    return _reviews.map((r) => r.rating).reduce((a, b) => a + b) /
        _reviews.length;
  }
}
