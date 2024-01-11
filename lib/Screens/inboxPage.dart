import 'package:flutter/material.dart';
import 'package:rent_house/Views/ListWidgets.dart';

import 'conversationPage.dart';

class InboxPage extends StatefulWidget {

  const InboxPage({super.key});


  @override
  State<InboxPage> createState() => _MyInboxPageState();
}

class _MyInboxPageState extends State<InboxPage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top:15.0),
      child: ListView.builder(
          itemCount: 2,
          itemExtent: MediaQuery.of(context).size.height/7,
          itemBuilder: (context,index){
            return InkResponse(
              child: ConversationListTilePage(),
            onTap: (){
              Navigator.pushNamed(
                  context,
                ConversationPage.routeName,
              );
            },);
          },
      ),
    );
  }
}
