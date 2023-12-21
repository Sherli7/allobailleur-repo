import 'package:flutter/material.dart';

class ExplorePage extends StatefulWidget {

  const ExplorePage({super.key});


  @override
  State<ExplorePage> createState() => _MyExplorePageState();
}

class _MyExplorePageState extends State<ExplorePage> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Explore Page'
      ),
    );
  }
}
