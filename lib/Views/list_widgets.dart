import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:rent_house/Models/AppConstants.dart';

class ReviewListTitle extends StatelessWidget {
  const ReviewListTitle({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder review data
    const String reviewerName = 'John Doe';
    const double rating = 4.5;
    const String reviewText =
        'Great property, very clean and well-maintained. Highly recommended!';

    return ListTile(
      leading: const CircleAvatar(
        child: Icon(Icons.person),
      ),
      title: Text(reviewerName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RatingBarIndicator(
            rating: rating,
            itemBuilder: (context, index) => const Icon(
              Icons.star,
              color: AppConstants.ratingStarColor,
            ),
            itemCount: 5,
            itemSize: 20.0,
          ),
          const SizedBox(height: 4),
          Text(reviewText),
        ],
      ),
    );
  }
}
