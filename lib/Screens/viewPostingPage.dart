import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rent_house/Models/property.dart';
import 'package:rent_house/Screens/BookPostingPage.dart';
import 'package:rent_house/Views/list_widgets.dart';
import 'package:rent_house/Views/text_widgets.dart';
import 'package:rent_house/Views/formWidgets.dart';

class ViewPostingPage extends StatefulWidget {
  static const String routeName = '/viewPostingPageRoute';

  final Property property;

  const ViewPostingPage({super.key, required this.property});

  @override
  State<ViewPostingPage> createState() => _MyViewPostingPageState();
}

class _MyViewPostingPageState extends State<ViewPostingPage> {
  final List<String> _amenities = [
    'Hair dryer',
    'Dishwasher',
    'Iron',
    'Wifi',
    'Carport'
  ];

  late Completer<GoogleMapController> _completer;
  late LatLng _centerLatLng;

  @override
  void initState() {
    super.initState();
    _centerLatLng = LatLng(widget.property.latitude, widget.property.longitude);
    _completer = Completer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: AppBarText(key: UniqueKey(), text: 'Posting Information'),
        actions: <Widget>[
          IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.save,
                color: Colors.white,
              ))
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            AspectRatio(
              aspectRatio: 3 / 2,
              child: PageView.builder(
                itemCount: widget.property.imageUrls.isEmpty
                    ? 1
                    : widget.property.imageUrls.length,
                itemBuilder: (context, index) {
                  if (widget.property.imageUrls.isEmpty) {
                    return const Image(
                      image: AssetImage('assets/images/house.jpeg'),
                      fit: BoxFit.fill,
                    );
                  }
                  return Image.network(
                    widget.property.imageUrls[index],
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 25, 25, 0),
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
                            width: MediaQuery.of(context).size.width / 2,
                            child: AutoSizeText(
                              widget.property.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 30.0),
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: <Widget>[
                          MaterialButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                  context, BookPostingPage.routeName);
                            },
                            color: Colors.redAccent,
                            child: const Text(
                              'Book now',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          Text(
                            '${widget.property.price} FCFA / Month',
                            style: const TextStyle(fontSize: 15.0),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 35.0, bottom: 25.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 1.75,
                          child: AutoSizeText(
                            widget.property.description,
                            style: const TextStyle(),
                            minFontSize: 18.0,
                            maxFontSize: 22.0,
                            maxLines: 5,
                          ),
                        ),
                        // Owner info removed for now to be replaced with dynamic data later
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 25.0),
                    child: ListView(
                      shrinkWrap: true,
                      children: <Widget>[
                        PostingInfoTile(
                          iconData: Icons.hotel,
                          category: '${widget.property.bedrooms} Bedrooms',
                          categoryInfo: ' 1 King', // This is static for now
                        ),
                        PostingInfoTile(
                          iconData: Icons.wc,
                          category: '${widget.property.bathrooms} Bathroom',
                          categoryInfo: '1 full', // This is static for now
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'Amenities',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 25.0),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 25.0, bottom: 25.0),
                    child: GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      childAspectRatio: 4 / 1,
                      children: List.generate(_amenities.length, (index) {
                        return Text(
                          _amenities[index],
                          style: const TextStyle(fontSize: 25.0),
                        );
                      }),
                    ),
                  ),
                  const Text(
                    'The Location',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 25.0),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 25.0, bottom: 25.0),
                    child: Text(
                      widget.property.city,
                      style: const TextStyle(fontSize: 25.0),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 25.0),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height / 3,
                      child: GoogleMap(
                        onMapCreated: (controller) {
                          _completer.complete(controller);
                        },
                        mapType: MapType.normal,
                        initialCameraPosition: CameraPosition(
                          target: _centerLatLng,
                          zoom: 11.0,
                        ),
                        markers: <Marker>{
                          Marker(
                            markerId: const MarkerId("House Location"),
                            position: _centerLatLng,
                            icon: BitmapDescriptor.defaultMarker,
                          ),
                        },
                      ),
                    ),
                  ),
                  const Text(
                    'Reviews',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 25.0),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 20.0),
                    child: ReviewForm(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: ListView.builder(
                      itemCount: 2,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding:
                              const EdgeInsets.only(top: 10.0, bottom: 10.0),
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

class PostingInfoTile extends StatelessWidget {
  final IconData iconData;
  final String category;
  final String categoryInfo;

  const PostingInfoTile(
      {super.key,
      required this.iconData,
      required this.category,
      required this.categoryInfo});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        iconData,
        size: 30.0,
      ),
      title: Text(
        category,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25.0),
      ),
      subtitle: Text(
        categoryInfo,
        style: const TextStyle(fontSize: 25.0),
      ),
    );
  }
}
