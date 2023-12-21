import 'package:flutter/material.dart';

class InboxPage extends StatefulWidget {

  const InboxPage({super.key});


  @override
  State<InboxPage> createState() => _MyInboxPageState();
}

class _MyInboxPageState extends State<InboxPage> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
          'Inbox Page'
      ),
    );
  }
}
