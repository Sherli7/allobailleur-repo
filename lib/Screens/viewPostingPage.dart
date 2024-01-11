import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rent_house/Screens/BookPostingPage.dart';
import 'package:rent_house/Screens/viewProfilePage.dart';
import 'package:rent_house/Views/ListWidgets.dart';
import 'package:rent_house/Views/TextWidgets.dart';
import 'package:rent_house/Views/formWidgets.dart';

class ViewPostingPage extends StatefulWidget {
  static const String routeName = '/viewPostingPageRoute';

  const ViewPostingPage({super.key});


  @override
  State<ViewPostingPage> createState() => _MyViewPostingPageState();
}

class _MyViewPostingPageState extends State<ViewPostingPage> {

  final List<String> _amenities=[
    'Hair dryer',
    'Dishwasher',
    'Iron',
    'Wifi',
    'Carport'
  ];

  final LatLng _centerLatLng=const LatLng(3.816350,11.489400);
  late Completer<GoogleMapController> _completer;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _completer = Completer();
  }

  void _requestLocationPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      print("Location permission granted");
    } else {
      print("Location permission denied");
    }
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
                    return const Image(
                      image: AssetImage('assets/images/house.jpeg'),
                      fit: BoxFit.fill,
                    );
                  },
              ),
            ),
            Padding(
                padding: const EdgeInsets.fromLTRB(25, 25,25, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[

                          SizedBox(
                            width:MediaQuery.of(context).size.width/2,
                            child: const AutoSizeText(
                              'Awesome Apartment',
                              style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 30.0
                            ),
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: <Widget>[
                         MaterialButton(onPressed: (){
                           Navigator.pushNamed(
                               context,
                               BookPostingPage.routeName
                           );
                         },
                         color: Colors.redAccent,
                         child: const Text(
                           'Book now',
                           style: TextStyle(
                             color: Colors.white
                           ),
                         ),
                         ),
                          const Text(
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
                        SizedBox(
                          width:MediaQuery.of(context).size.width/1.75,
                          child: const AutoSizeText(
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
                              backgroundColor: Colors.black,
                              child:
                              GestureDetector(
                                onTap: (){
                                  Navigator.pushNamed(
                                      context,
                                      ViewProfilePage.routeName
                                  );
                                },
                                child: CircleAvatar(
                                  backgroundImage: const AssetImage('assets/images/sherli7.jpg'),
                                  radius: MediaQuery.of(context).size.width/12,
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(top:10.0),
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
                  Padding(
                    padding: const EdgeInsets.only(bottom: 25.0),
                    child: ListView(
                      shrinkWrap: true,
                      children: const <Widget> [
                        PostingInfoTile(
                            iconData: Icons.home,
                            category: 'Apartment',
                            categoryInfo: '2 guests',
                        ),
                        PostingInfoTile(
                          iconData: Icons.hotel,
                          category: '1 Bedrooms',
                          categoryInfo: ' 1 King',
                        ),
                        PostingInfoTile(
                          iconData: Icons.wc,
                          category: 'Bathroom',
                          categoryInfo: '1 full',
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'Amenities',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 25.0
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top:25.0, bottom: 25.0),
                    child: GridView.count(
                      shrinkWrap: true,
                        crossAxisCount: 2,
                      childAspectRatio: 4/1,
                      children: List.generate(_amenities.length, (index) {
                        return Text(
                          _amenities[index],
                          style: const TextStyle(
                              fontSize: 25.0
                          ),
                        );
                      }),
                    ),
                  ),
                  const Text(
                    'The Location',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 25.0
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top:25.0,bottom: 25.0),
                    child: Text(
                      'Rond point damas,Yaoundé',
                      style: TextStyle(
                          fontSize: 25.0
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 25.0),
                    child: Container(
                      height: MediaQuery.of(context).size.height / 3,
                      child: GoogleMap(
                        onMapCreated: (controller){
                          _completer.complete(controller);
                        },
                        mapType: MapType.normal,
                        initialCameraPosition: CameraPosition(
                          target: _centerLatLng,
                          zoom: 11.0,
                        ),
                        markers: <Marker> {
                          Marker(
                            markerId: MarkerId("House Location"),
                            position: _centerLatLng,
                            icon: BitmapDescriptor.defaultMarker,
                          ),
                        },
                      ),
                    ),
                  ),
                  const Text(
                    'Reviews',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 25.0
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 20.0),
                    child: ReviewForm(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child:ListView.builder(
                      itemCount: 2,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(top:10.0, bottom: 10.0),
                          child: ReviewListTitle(key: UniqueKey()),
                        ); // Adjust this according to how ReviewListTitle is defined
                      },
                    ),
                  ),
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
  final IconData iconData;
  final String category;
  final String categoryInfo;

  const PostingInfoTile({super.key, required this.iconData, required this.category, required this.categoryInfo});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
          iconData,
          size: 30.0,
      ),
      title: Text(
        category,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 25.0
        ),
      ),
      subtitle:Text(
        categoryInfo,
        style: const TextStyle(
            fontSize: 25.0
        ),
      ),
    );
  }

}
