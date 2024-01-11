import 'package:flutter/material.dart';
import 'package:rent_house/Views/TextWidgets.dart';

class ConversationPage extends StatefulWidget {
  static const String routeName = '/conversationTilePageRoute';

  const ConversationPage({super.key});


  @override
  State<ConversationPage> createState() => ConversationPageState();
}

class ConversationPageState extends State<ConversationPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: AppBarText(key: UniqueKey(), text: 'Lionel'),
      ),
      body: Column(
        children: <Widget>[
          //ListView.builder(itemBuilder: itemBuilder)
          Expanded(child: Container(),),

         Container(
           decoration: BoxDecoration(
             border: Border.all(
               color: Colors.black,
             )
           ),
           child: Row(
             mainAxisSize: MainAxisSize.max,
             children: <Widget>[
               Container(
                 width: MediaQuery.of(context).size.width*5/6,
                 child: TextField(
                   decoration: InputDecoration(
                     hintText: 'Write a message',
                     contentPadding: EdgeInsets.all(20.0),
                     border: InputBorder.none
                   ),
                   minLines: 1,
                   maxLines: 5,
                   style: TextStyle(
                     fontSize: 20.0
                   ),
                 ),
               ),
               Expanded(
                 child: MaterialButton(onPressed: (){},
                 child: Text(
                   'Send',
                 ),
                 ),
               )
             ],
           ),
         )
        ],
      ),
    );
  }
}
