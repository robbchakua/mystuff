import 'dart:async';
import 'dart:io';
import 'package:location/location.dart' as location_import;
import 'package:dad_app/models/location_model.dart';
import 'package:dad_app/styles/themes.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item_model.dart';

//Debug
bool myPrintBool = false;
bool printInsteadOfPostBool = false;
bool resetUserDataBool = false;
bool showTestingItemsBool = false;
bool developingPageBool = false;
Widget developingPageWidget = const Placeholder();

//User
late SharedPreferences preferences;
LatLng userLocation = const LatLng(0, 0);
double userLocationAccuracy = 0;
String firstName = '';
bool transitionMap = false;
bool darkModeMap = false;

//Program
bool processing = false;

//PV stands for Global Variable. Reason being it originally conflicted with an existing variable
location_import.Location gvLocation = location_import.Location();
bool isDarkTheme = true;
bool listItems = false;
TextEditingController emailController = TextEditingController();
TextEditingController searchController = TextEditingController();
PageController pageViewController = PageController(
  initialPage: 0,
);
Completer<GoogleMapController> googleMapsController = Completer();
List<Item> itemsJsonList = [];
List<Item> itemsUpdatingList = [];
int itemsUpdatingListLength = 0;
List<Location> locationsJsonList = [];
List<Location> locationsUpdatingList = [];
int locationsUpdatingListLength = 0;
List<String> locationsCloseToUserList = [];
bool locationCloseToUser = false;
bool listLocations = false;
bool isLoaded = false;
bool noItems = false;
bool userNotFound = false;
bool incorrectPassword = false;
File file = File("");
Set<Marker> markers = {};
LatLng targetPosition = const LatLng(0, 0);
double cameraZoom = 17;
DateTime timeNow = DateTime.now();
bool networkError = false;

enum SortValue { dateSaved, name, nearMe }

///Replace any characters that could affect the database.
/// - "'" can make the query end.
/// - '"' can make the query end.
/// - ',,,' used to separate the locations and items on get.
/// - '\n' can create problems in the database.
String safeString(String string) => string
    .trim()
    .replaceAll("'", '')
    .replaceAll('"', '')
    .replaceAll(',,,', '')
    .replaceAll("\n", '');

LatLng stringToLatLng(String string) {
  try {
    List res = string.split(',');
    return LatLng(double.parse(res[0]), double.parse(res[1]));
  } catch (e) {
    return const LatLng(0, 0);
  }
}

String? latLngToString(LatLng? latLng) =>
    "${latLng?.latitude},${latLng?.longitude}";

Color stringToColor(String string) =>
    Color(int.parse(string.substring(0, 6), radix: 16) + 0xFF000000);

String? colorToString(Color? color) =>
    color?.value.toRadixString(16).toUpperCase().substring(2);

int nextItemId() {
  if (itemsJsonList.isNotEmpty) {
    return itemsJsonList.last.id! + 1;
  } else {
    return 1;
  }
}

int nextLocationId() {
  if (locationsJsonList.isNotEmpty) {
    return locationsJsonList.last.id! + 1;
  } else {
    return 1;
  }
}

int getItemIndexFromId(int id) {
  List<int> ids = [];
  for (var i = 0; i < itemsJsonList.length; i++) {
    ids.add(itemsJsonList[i].id!);
  }
  return ids.indexOf(id);
}

int getLocationIndexFromId(int id) {
  List<int> ids = [];
  for (var i = 0; i < locationsJsonList.length; i++) {
    ids.add(locationsJsonList[i].id!);
  }
  return ids.indexOf(id);
}

int getLocationIdFromName(String str) {
  int x = 0;
  for (var i = 0; i < locationsJsonList.length; i++) {
    if (str == locationsJsonList[i].name) {
      x = locationsJsonList[i].id!;
      break;
    }
  }
  return x;
}

Location? getLocationFromId(int? id) {
  if (id == null) return null;
  for (final bin in locationsJsonList) {
    if (bin.id == id) return bin;
  }
  return null;
}

int binDepth(Location bin) {
  var depth = 0;
  var parentId = bin.parentId;
  final visited = <int>{};
  while (parentId != null && !visited.contains(parentId)) {
    visited.add(parentId);
    final parent = getLocationFromId(parentId);
    if (parent == null) break;
    depth++;
    parentId = parent.parentId;
  }
  return depth;
}

String binDisplayPath(Location bin) {
  final names = <String>[bin.name ?? 'Unnamed bin'];
  var parentId = bin.parentId;
  final visited = <int>{};
  while (parentId != null && !visited.contains(parentId)) {
    visited.add(parentId);
    final parent = getLocationFromId(parentId);
    if (parent == null) break;
    names.insert(0, parent.name ?? 'Unnamed bin');
    parentId = parent.parentId;
  }
  return names.join(' / ');
}

List<Location> editableBins() =>
    locationsJsonList.where((bin) => bin.canEdit).toList()
      ..sort((a, b) => binDisplayPath(a).compareTo(binDisplayPath(b)));

double screenHeight(BuildContext context) => MediaQuery.sizeOf(context).height;

double screenWidth(BuildContext context) => MediaQuery.sizeOf(context).width;

double screenHeightWithSafeArea(BuildContext context) =>
    screenHeight(context) - MediaQuery.of(context).padding.top;

class MyStuffLogo extends StatelessWidget {
  MyStuffLogo({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
        backgroundColor: inverseColor(context),
        radius: screenWidth(context) / ((size ?? 3) * 2) + 2,
        child: Image.asset(
          'assets/images/logo1024.png',
          width: screenWidth(context) / (size ?? 3),
          height: screenWidth(context) / (size ?? 3),
        ));
  }
}

class RusmarkLogo extends StatelessWidget {
  const RusmarkLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
        backgroundColor: Colors.black,
        radius: screenWidth(context) / 6 + 2,
        child: CircleAvatar(
          backgroundColor: Colors.white,
          radius: screenWidth(context) / 6,
          child: Image.asset(
            'assets/images/rusmarklogo.png',
            width: screenWidth(context) / 3.5,
            height: screenWidth(context) / 3.5,
          ),
        ));
  }
}

class MyNetworkError extends StatelessWidget {
  const MyNetworkError({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error, color: Colors.grey),
        Text(
          'Error trying to load items',
          style: TextStyle(color: Colors.grey),
        )
      ],
    );
  }
}

// String? authors;
// String? titles;

// void getKeyword({required String keyword}) {
//   for (var i = 0; i < jsonList.length; i++) {
//     bool found = jsonList[i]
//         .author!
//         .toLowerCase()
//         .contains(keyword.toLowerCase()) ||
//         jsonList[i].title!.toLowerCase().contains(keyword.toLowerCase());
//     if (found) {
//       setState(() {
//         authors = jsonList[i].author!;
//         titles = jsonList[i].title!;
//       });
//     }
//   }
//   return;
// }
//
// void getDataWithParams({required List keyword}) async {
//   try {
//     setState(() {
//       isLoaded = false;
//     });
//     Dio dio = Dio();
//     Response response = await dio.post(
//         'https://rusmark.io.ke/get_with_params.php',
//         data: {'author': keyword[0],
//           'title': keyword[1]});
//     if (response.statusCode == 200) {
//       setState(() {
//         jsonList = booksFromJson(response.data);
//         isLoaded = true;
//         updatedList = jsonList;
//       });
//     } else {
//       setState(() {
//         isLoaded = true;
//       });
//     }
//   } catch (e) {
//     setState(() {
//       isLoaded = true;
//     });
//     print(e);
//   }
// }
