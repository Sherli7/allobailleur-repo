import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ReviewForm extends StatefulWidget {  @override

const ReviewForm({super.key});

  @override
  ReviewFormState createState()=>ReviewFormState();
}


class ReviewFormState extends State<ReviewForm>{
  @override
  Widget build(BuildContext context) {
   return Container(
     decoration: BoxDecoration(
       border: Border.all(
         color: Colors.black,
         width: 2.0,
       ),
       borderRadius: BorderRadius.circular(10.0),
     ),
     child: Padding(
       padding: const EdgeInsets.all(15.0),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.end,
         children: <Widget>[
           Form(
               child: Column(
                 children:<Widget> [
                   TextFormField(
                     decoration: const InputDecoration(
                       hintText: 'Enter review'
                     ),
                     maxLines: 2,
                     style: const TextStyle(
                       fontSize: 20.0
                     ),
                   ),
                   Padding(
                     padding: const EdgeInsets.only(top:10.0, bottom: 10.0),
                     child: RatingBar.builder(
                       initialRating: 2.5, // Example rating value
                       minRating: 1,
                       direction: Axis.horizontal,
                       allowHalfRating: true,
                       itemCount: 5,
                       itemSize: 30.0, // Size of each star
                       itemBuilder: (context, _) => const Icon(
                         Icons.star,
                         color: Colors.deepOrangeAccent,
                       ),
                       onRatingUpdate: (rating) {
                         print(rating);
                       },
                     ),
                   ),
                 ],
               ),
           ),
           MaterialButton(
             onPressed: (){},
             color: Colors.lightBlue,
             child: const Text('Submit'),
           ),
         ],
       ),
     ),
   );
  }

}