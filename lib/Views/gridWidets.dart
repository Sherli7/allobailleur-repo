import 'package:auto_size_text/auto_size_text.dart';
// Pour debugPrint
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:rent_house/Models/AppConstants.dart';

class PostingGridTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final String price;
  final double initialRating;
  final String imagePath;

  const PostingGridTile({
    super.key,
    this.title = 'Apartement - Yaounde,YDE',
    this.subtitle = 'Awesome Apartment',
    this.price = '850000 FCFA / month',
    this.initialRating = 4.5,
    this.imagePath = 'assets/images/house.jpeg',
  });

  @override
  State<PostingGridTile> createState() => _PostingGridTileState();
}

class _PostingGridTileState extends State<PostingGridTile> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 3 / 2,
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(widget.imagePath),
                fit: BoxFit.fill,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Flexible(
          child: AutoSizeText(
            widget.title,
            style: const TextStyle(
              fontSize: 15.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        Flexible(
          child: AutoSizeText(
            widget.subtitle,
            style: const TextStyle(
              fontSize: 12.0,
              color: Colors.black,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        Text(widget.price),
        const Spacer(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            RatingBar.builder(
              initialRating: widget.initialRating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 20.0,
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: AppConstants.ratingStarColor,
              ),
              onRatingUpdate: (rating) {
                debugPrint('Rating: $rating');
              },
            ),
          ],
        ),
      ],
    );
  }
}

class TripGridTile extends StatefulWidget {
  final String location;
  final String title;
  final String price;
  final String startDate;
  final String endDate;
  final double initialRating;
  final String imagePath;

  const TripGridTile({
    super.key,
    this.location = 'Yaounde,YDE',
    this.title = 'Awesome Apartment',
    this.price = '850000 FCFA / month',
    this.startDate = 'January 10, 2024',
    this.endDate = 'January 12, 2024',
    this.initialRating = 4.5,
    this.imagePath = 'assets/images/house.jpeg',
  });

  @override
  State<TripGridTile> createState() => _TripGridTileState();
}

class _TripGridTileState extends State<TripGridTile> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 3 / 2,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(widget.imagePath),
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: AutoSizeText(
              widget.location,
              style: const TextStyle(
                fontSize: 15.0,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: AutoSizeText(
              widget.title,
              style: const TextStyle(
                fontSize: 12.0,
                color: Colors.black,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Text(widget.price),
          const SizedBox(height: 4),
          Text(
            '${widget.startDate} -',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            widget.endDate,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              RatingBar.builder(
                initialRating: widget.initialRating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 20.0,
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: AppConstants.ratingStarColor,
                ),
                onRatingUpdate: (rating) {
                  debugPrint('Rating: $rating');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
