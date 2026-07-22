import 'package:dad_app/pages/home.dart';
import 'package:flutter/material.dart';
import 'package:dad_app/utils/utils.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io';
import '../models/user_model.dart';

void getMarkers() async {
  markers = {};
  for (var i = 0; i < locationsJsonList.length; i++) {
    if (locationsJsonList[i].location!.contains(',')) {
      double color =
          HSLColor.fromColor(stringToColor(locationsJsonList[i].color!)).hue;
      LatLng location = stringToLatLng(locationsJsonList[i].location!);
      markers.add(Marker(
          icon: BitmapDescriptor.defaultMarkerWithHue(color),
          markerId: MarkerId(locationsJsonList[i].id.toString()),
          position: location,
          infoWindow: InfoWindow(
            title: locationsJsonList[i].name,
            snippet: 'View items',
            onTap: () {
              listItems = true;
              final visibleBinIds =
                  binAndDescendantIds(locationsJsonList[i].id!);
              itemsUpdatingList = itemsJsonList
                  .where((item) => visibleBinIds.contains(item.binId))
                  .toList();
              itemsUpdatingListLength = itemsUpdatingList.length;
              Get.to(() => const Home());
            },
          )));
    }
  }
}

void clearData() {
  User.user = User();
  itemsJsonList = [];
  itemsUpdatingList = [];
  locationsUpdatingList = [];
  locationsJsonList = [];
  isLoaded = false;
  noItems = false;
  userNotFound = false;
  incorrectPassword = false;
  userLocation = const LatLng(0, 0);
  file = File('');
  locationsCloseToUserList = [];
  emailController.text = '';
  markers = {};
  networkError = false;
}

void resetLocationList() {
  locationsUpdatingList = [];
  for (var i = 0; i < locationsJsonList.length; i++) {
    locationsUpdatingList.add(locationsJsonList[i]);
  }
  locationsUpdatingListLength = locationsUpdatingList.length;
}

void resetItemList() {
  itemsUpdatingList = [];
  for (var i = 0; i < itemsJsonList.length; i++) {
    itemsUpdatingList.add(itemsJsonList[i]);
  }
  itemsUpdatingListLength = itemsUpdatingList.length;
}

///Debugging purposes. Prints to console
void myPrint(Object? data) {
  if (myPrintBool) {
    print(data);
  }
}

void debugPreferences(
    {required bool print,
    required bool printInsteadOfPost,
    required bool resetUserData,
    required bool showTestingItems,
    required bool developingPage,
    Widget? page}) {
  if (print) {
    myPrintBool = true;
  }
  if (printInsteadOfPost) {
    printInsteadOfPostBool = true;
  }
  if (resetUserData) {
    resetUserDataBool = true;
  }
  if (showTestingItems) {
    showTestingItemsBool = true;
  }
  if (developingPage) {
    developingPageBool = true;
    developingPageWidget = page!;
  }
}
