import 'dart:async';
import 'dart:math';
import 'package:dad_app/pages/home.dart';
import 'package:dad_app/utils/constants.dart';
import 'package:dad_app/utils/init.dart';
import 'package:dad_app/styles/themes.dart';
import 'package:dad_app/utils/utils.dart';
import 'package:dad_app/widgets/bin_drawer.dart';
import 'package:dad_app/widgets/text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import '../styles/google_maps_styles.dart';

class ItemLocationScreen extends StatefulWidget {
  final bool withTarget;

  const ItemLocationScreen({super.key, required this.withTarget});

  @override
  State<ItemLocationScreen> createState() => _ItemLocationScreenState();
}

class _ItemLocationScreenState extends State<ItemLocationScreen> {
  GlobalKey<ScaffoldState> locationScaffoldKey =
      GlobalKey<ScaffoldState>(debugLabel: 'locationScaffold');

  Set<Marker> viewMarkers = {};
  LatLng targetedPosition = const LatLng(30, 30);
  MapType mapType = MapType.normal;
  bool isChecked = false;

  void checkLocationsInProximity() {
    setState(() {
      locationsCloseToUserList = [];
    });
    for (var i = 0; i < locationsJsonList.length; i++) {
      double lat = targetPosition.latitude;
      double lng = targetPosition.longitude;

      double lowerBoundLat =
          stringToLatLng(locationsJsonList[i].location!).latitude - fiftyMeters;
      double upperBoundLat =
          stringToLatLng(locationsJsonList[i].location!).latitude + fiftyMeters;
      double lowerBoundLng =
          stringToLatLng(locationsJsonList[i].location!).longitude -
              fiftyMeters;
      double upperBoundLng =
          stringToLatLng(locationsJsonList[i].location!).longitude +
              fiftyMeters;

      if (lowerBoundLat <= lat &&
          lat <= upperBoundLat &&
          lowerBoundLng <= lng &&
          lng <= upperBoundLng) {
        locationsCloseToUserList.add(locationsJsonList[i].name!);
      }
    }
  }

  void onCameraMove(CameraPosition position) {
    targetPosition = position.target;
    setState(() {
      cameraZoom = position.zoom;
    });
    if (transitionMap) {
      if (position.zoom >= 17) {
        setState(() {
          mapType = MapType.satellite;
        });
      } else if (position.zoom <= 17) {
        setState(() {
          mapType = MapType.normal;
        });
      }
    }
  }

  @override
  initState() {
    mapInit();
    super.initState();
  }

  Future mapInit() async {
    if (widget.withTarget) {}
  }

  @override
  void dispose() {
    locationScaffoldKey.currentState?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Future(
      () async {
        LocationData locationData = await Location().getLocation();
        userLocation = LatLng(locationData.latitude!, locationData.longitude!);
        userLocationAccuracy = locationData.accuracy!;
      },
    );

    return Scaffold(
      key: locationScaffoldKey,
      drawer: const BinDrawer(),
      appBar: AppBar(
        centerTitle: true,
        title: const SubHeader('View'),
        actions: [
          IconButton(
              onPressed: () {
                Get.to(() => const Home());
              },
              icon: const Icon(Icons.home)),
        ],
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            );
          },
        ),
      ),
      body: SafeArea(
        child: SizedBox(
          height: screenHeight(context),
          width: screenWidth(context),
          child: Stack(
            children: [
              GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    if (darkModeMap) {
                      controller.setMapStyle(googleMapsDarkMode);
                    }
                    googleMapsController = Completer();
                    googleMapsController.complete(controller);
                  },
                  mapType: mapType,
                  onCameraMove: onCameraMove,
                  markers: markers,
                  zoomControlsEnabled: false,
                  buildingsEnabled: false,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  mapToolbarEnabled: false,
                  trafficEnabled: false,
                  initialCameraPosition: CameraPosition(
                      target: widget.withTarget ? targetPosition : userLocation,
                      zoom: cameraZoom)),
              Center(
                  child: Icon(
                Icons.add,
                color: secondaryColor(context),
              )),
              Align(
                alignment: Alignment.bottomRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    myPrintBool
                        ? Padding(
                            padding: EdgeInsets.all(screenHeight(context) / 70),
                            child: FloatingActionButton(
                              heroTag: 'debug-button-1',
                              onPressed: checkLocationsInProximity,
                              backgroundColor: Colors.red,
                              child: Icon(
                                Icons.where_to_vote_outlined,
                                size: 36,
                                color: inverseColor(context),
                              ),
                            ),
                          )
                        : Container(),
                    myPrintBool
                        ? Padding(
                            padding: EdgeInsets.all(screenHeight(context) / 70),
                            child: FloatingActionButton(
                              heroTag: 'debug-button-2',
                              onPressed: () {
                                String id =
                                    'debug-marker-${Random().nextInt(100)}';
                                markers.add(Marker(
                                    position: targetPosition,
                                    markerId: MarkerId(id)));
                                myPrint(id);
                              },
                              backgroundColor: Colors.red,
                              child: Icon(
                                Icons.add_location,
                                size: 36,
                                color: inverseColor(context),
                              ),
                            ),
                          )
                        : Container(),
                    Padding(
                      padding: EdgeInsets.all(screenHeight(context) / 70),
                      child: FloatingActionButton(
                        heroTag: 'none-debug',
                        onPressed: () async {
                          GoogleMapController controller =
                              await googleMapsController.future;
                          controller.animateCamera(
                              CameraUpdate.newCameraPosition(CameraPosition(
                                  target: userLocation,
                                  zoom: cameraZoom >= 17 ? cameraZoom : 17)));
                        },
                        backgroundColor: Colors.green,
                        child: Icon(
                          Icons.my_location,
                          size: 36,
                          color: inverseColor(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              myPrintBool
                  ? Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                          color: primaryColor(context),
                          child: BodyText(
                              "Current Location Accuracy: $userLocationAccuracy\n"
                              "Latitude: ${targetPosition.latitude}\n"
                              "Longitude: ${targetPosition.longitude}\n"
                              "Zoom: ${cameraZoom}x\n"
                              "Location in 50m Proximity: $locationsCloseToUserList")),
                    )
                  : const Row(),
              processing
                  ? Container(
                      height: screenHeight(context),
                      width: screenWidth(context),
                      color: const Color(0xAA000000),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SubHeader('Deleting Bin...')
                        ],
                      ))
                  : const Row()
            ],
          ),
        ),
      ),
    );
  }
}
