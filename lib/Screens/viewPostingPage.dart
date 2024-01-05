import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:rent_house/Screens/guestHomePage.dart';
import 'package:rent_house/Views/TextWidgets.dart';
import 'package:rent_house/Views/formWidgets.dart';

class ViewPostingPage extends StatefulWidget {
  static const String routeName = '/viewPostingPageRoute';

  const ViewPostingPage({super.key});


  @override
  State<ViewPostingPage> createState() => _MyViewPostingPageState();
}

class _MyViewPostingPageState extends State<ViewPostingPage> {

  void _signup(){
    Navigator.pushNamed(context, GuestHomePage.routeName);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: AppBarText(key: UniqueKey(), text: 'Posting Information'),
        actions: <Widget> [
          IconButton(
              onPressed: (){},
              icon: const Icon(Icons.save,color: Colors.white,))
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget> [
            AspectRatio(
              aspectRatio: 3/2,
              child: PageView.builder(
                  itemCount: 3,
                  itemBuilder: (context,index){
                    return Image(
                      image: AssetImage('assets/images/house.jpeg'),
                      fit: BoxFit.fill,
                    );
                  },
              ),
            ),
            Padding(
                padding: const EdgeInsets.fromLTRB(25, 25,25, 0),
              child: Column(
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[

                          Container(
                            width:MediaQuery.of(context).size.width/2,
                            child: AutoSizeText(
                              'Awesome Apartment',
                              style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 30.0
                            ),
                              // maxFontSize: 30.0,
                              // minFontSize: 21.0,
                              maxLines: 2,
                            ),
                          ),
/*                          Padding(
                            padding: const EdgeInsets.only(top: 5.0),
                            child: Text(
                              'Apartment', style: TextStyle(
                                fontSize: 20.0
                            ),
                            ),
                          ),*/
                        ],
                      ),
                      Column(
                        children: <Widget>[
                         MaterialButton(onPressed: (){},
                         color: Colors.redAccent,
                         child: Text(
                           'Book now',
                           style: TextStyle(
                             color: Colors.white
                           ),
                         ),
                         ),
                          Text(
                            '135000 FCFA / Month',
                            style: TextStyle(
                              fontSize: 15.0
                          ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top:35.0, bottom: 25.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:<Widget> [
                        Container(
                          width:MediaQuery.of(context).size.width/1.75,
                          child: AutoSizeText(
                              'A quiet, cozy place in the eart of the city. Easy to get to wherever you need to go!',
                            style: TextStyle(
                            ),
                            minFontSize: 18.0,
                            maxFontSize: 22.0,
                            maxLines: 5,
                          ),
                        ),
                        Column(
                          children: <Widget> [
                            CircleAvatar(
                              radius: MediaQuery.of(context).size.width/10.5,
                              child: CircleAvatar(
                                backgroundImage: AssetImage('assets/images/sherli7.jpg'),
                                radius: MediaQuery.of(context).size.width/12,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top:10.0),
                              child: Text(
                                'Sherli7',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  ListView(
                    shrinkWrap: true,
                    children: <Widget> [
                      PostingInfoTile(
                          icon: Icon(Icons.home),
                          category: 'Apartment',
                          categoryInfo: '2 guests',
                      )
                    ],
                  ),
                  Text(""),
                  Text("Amenities"),
                  //GridView.count(crossAxisCount: crossAxisCount)
                  Text("The Location"),
                  Container(),
                  Text("Reviews"),
                  ReviewForm(),
                ],
              ),
            ),
           // ListView.builder(itemBuilder: itemBuilder)
          ],
        ),
      ),
    );
  }
}

class PostingInfoTile extends StatelessWidget{
  final Icon icon;
  final String category;
  final String categoryInfo;

  PostingInfoTile({super.key, required this.icon, required this.category, required this.categoryInfo});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon,
      title: Text(
        category,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 25.0
        ),
      ),
      subtitle:Text(
        categoryInfo,
        style: TextStyle(
            fontSize: 25.0
        ),
      ),
    );
  }

}
