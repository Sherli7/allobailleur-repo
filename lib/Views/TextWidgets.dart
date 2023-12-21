import 'package:flutter/material.dart';

class AppBarText extends StatelessWidget{
  final String text;
  const AppBarText({required Key key,required this.text}):super(key:key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 25.0
      ),
    );
  }

}