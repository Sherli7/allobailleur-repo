import 'package:flutter/material.dart';

class TripsPage extends StatefulWidget {

  const TripsPage({super.key});


  @override
  State<TripsPage> createState() => _MyTripsPageEState();
}

class _MyTripsPageEState extends State<TripsPage> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
          'Trips Page'
      ),
    );
  }
}
