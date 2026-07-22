import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dad_app/models/item_model.dart';
import 'package:dad_app/models/location_distance_model.dart';
import 'package:dad_app/models/response_model.dart';
import 'package:dad_app/pages/location_page.dart';
import 'package:dad_app/models/user_model.dart';
import 'package:dad_app/utils/init.dart';
import 'package:dad_app/utils/item_status.dart';
import 'package:dad_app/widgets/drawer.dart';
import 'package:dad_app/widgets/text.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart' hide Response, FormData;
import 'package:flutter/material.dart' hide Title;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import '../styles/themes.dart';
import '../utils/utils.dart';
import '../utils/constants.dart';
import '../widgets/new_item_popup_card.dart';
import '../widgets/view_item_popup.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  GlobalKey<ScaffoldState> scaffoldKey =
      GlobalKey<ScaffoldState>(debugLabel: 'homeScaffold');
  List<Item> viewList = [];
  SortValue? sortValue;
  String _searchQuery = '';
  ItemStatus? _statusFilter;
  String? _tagFilter;
  int? _binFilter;

  Future confirmExit() => showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
            title: const Title('Alert'),
            content: const Header('Do you want to exit?'),
            actions: [
              TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    pop();
                  },
                  child: const ButtonText('Yes')),
              TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                  child: const ButtonText('No')),
            ],
          ));

  Future addItemPage() => showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
            content: const NewItemColumn(),
            backgroundColor: primaryColor(context),
          ));

  Future<void> addItem() async {
    if (editableBins().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              BodyText('Create a bin first, or ask an admin for edit access.'),
        ));
      }
      return;
    }
    await addItemPage();
    if (!mounted) return;
    setState(() {
      noItems = itemsJsonList.isEmpty;
      _applyItemFilters(notify: false);
    });
  }

  Future<void> addBin() async {
    if (networkError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: BodyText('Network Error...')),
      );
      return;
    }
    if (!isLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: BodyText('Items still loading...')),
      );
      return;
    }

    setState(() => processing = true);
    try {
      if (userLocation == const LatLng(0, 0)) {
        final locationData = await gvLocation.getLocation();
        userLocation = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );
      }
      targetPosition = userLocation;
      listLocations = true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: BodyText('Could not get your location')),
        );
      }
      return;
    } finally {
      if (mounted) setState(() => processing = false);
    }

    if (!mounted) return;
    await Get.to(() => const ItemLocationScreen(
          withTarget: false,
          addBinMode: true,
        ));
    if (mounted) setState(() {});
  }

  Future<void> viewItem({
    required int id,
    required int locationId,
    required String name,
    required String location,
    required bool multiple,
    required int quantity,
    required String description,
    required List<String> tags,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: processing
            ? Colors.transparent
            : stringToColor(
                locationsJsonList[getLocationIndexFromId(locationId)].color!,
              ),
        content: ViewItemColumn(
          id: id,
          name: name,
          location: location,
          multiple: multiple,
          quantity: quantity,
          description: description,
          tags: tags,
          locationId: locationId,
        ),
      ),
    );
    if (mounted) _applyItemFilters();
  }

  static Future<void> pop({bool? animated}) async {
    await SystemChannels.platform
        .invokeMethod<void>('SystemNavigator.pop', animated);
  }

  @override
  void initState() {
    makeUserVariable();
    super.initState();
  }

  Future showAllMarkers(bool isComplete) async {
    //First Commented code...
    // If a marker is not in the bounds, ignore it.

    List<Marker> sortedMarkers = [];

    for (var i = 0; i < markers.length; i++) {
      double lat = markers.toList()[i].position.latitude;
      double lng = markers.toList()[i].position.longitude;

      double lowerBoundLat = userLocation.latitude - showMarkersRadius;
      double upperBoundLat = userLocation.latitude + showMarkersRadius;
      double lowerBoundLng = userLocation.longitude - showMarkersRadius;
      double upperBoundLng = userLocation.longitude + showMarkersRadius;

      if (lowerBoundLat <= lat &&
          lat <= upperBoundLat &&
          lowerBoundLng <= lng &&
          lng <= upperBoundLng) {
        sortedMarkers.add(markers.toList()[i]);
      }
    }

    if (sortedMarkers.isEmpty) {
      return;
    }

    if (sortedMarkers.length == 1) {
      final markerPosition = sortedMarkers.single.position;
      setState(() {
        cameraZoom = 17;
        targetPosition = markerPosition;
      });
      if (isComplete) {
        final controller = await googleMapsController.future;
        await controller.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(target: markerPosition, zoom: cameraZoom)));
      }
      return;
    }

    // Get farthest distance between all the markers from the usersLocation.
    sortedMarkers.sort((a, b) => sqrt(
            pow(a.position.latitude - userLocation.latitude, 2) +
                pow(a.position.longitude - userLocation.longitude, 2))
        .compareTo(sqrt(pow(b.position.latitude - userLocation.latitude, 2) +
            pow(b.position.longitude - userLocation.longitude, 2))));

    sortedMarkers = sortedMarkers.reversed.toList();
    Marker furthestMarker = sortedMarkers[0];

    //Get the furthest marker.

    sortedMarkers.sort((a, b) => sqrt(pow(
                a.position.latitude - furthestMarker.position.latitude, 2) +
            pow(a.position.longitude - furthestMarker.position.longitude, 2))
        .compareTo(sqrt(pow(
                b.position.latitude - furthestMarker.position.latitude, 2) +
            pow(b.position.longitude - furthestMarker.position.longitude, 2))));

    sortedMarkers = sortedMarkers.reversed.toList();

    //Get the distance of the furthest marker from the [sortedMarkers[0]]
    //and multiplying 110.574

    //If the length of [sortedMarkers] is <= 2 so that it targets
    //The other marker.

    //  [d] = 110.574 * √(
    //    [sortedMarkers[0].position.latitude] -
    //    [sortedMarkers[1].position.latitude]
    //   )² + (
    //    [sortedMarkers[0].position.longitude] -
    //    [sortedMarkers[1].position.longitude]
    //   )²

    double d = 110.574 *
        sqrt(pow(
                furthestMarker.position.latitude -
                    sortedMarkers[0].position.latitude,
                2) +
            pow(
                (furthestMarker.position.longitude -
                    sortedMarkers[0].position.longitude),
                2));

    //  [midPoint] = ((
    //    [sortedBooks[0].position.latitude] +
    //    [sortedBooks[1].position.latitude])/2),
    //   ([sortedBooks[0].position.longitude] +
    //   [sortedBooks[1].position.longitude])/2)

    LatLng midPoint = LatLng(
        (furthestMarker.position.latitude +
                sortedMarkers[0].position.latitude) /
            2,
        (furthestMarker.position.longitude +
                sortedMarkers[0].position.longitude) /
            2);

    //With this distance [d], let [[cameraZoom]] be the zoom
    //  [[cameraZoom]] = -((ln([d]/19567.88))/(ln(2))) + 1

    setState(() {
      cameraZoom = d == 0
          ? 17
          : (-((log(d / 156543) / log(2)) + 2)).clamp(2, 21).toDouble();
      targetPosition = midPoint;
    });

    // If the map is already initialized, then update camera position
    if (isComplete) {
      GoogleMapController controller = await googleMapsController.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: midPoint, zoom: cameraZoom)));
    }
  }

  void makeUserVariable() {
    Object? userString = preferences.get('user');
    List<User> tempList = [];

    setState(() {
      tempList = userFromJson(userString.toString());
      User.user = tempList[0];
      firstName = User.user.name!.split(" ").first;
    });
    setPreferences();
    if (itemsJsonList.isEmpty) {
      getData();
    }
  }

  void setPreferences() {
    if (preferences.getStringList('settings') == null) {
      preferences.setStringList('settings', <String>['false', 'false']);
    }
    List<String>? myList = preferences.getStringList('settings');
    setState(() {
      transitionMap = bool.parse(myList![0]);
      darkModeMap = bool.parse(myList[1]);
    });
  }

  ///Get data from database
  void getData() async {
    setState(() {
      // Reset original data and network error
      itemsJsonList = [];
      locationsJsonList = [];
      networkError = false;
      isLoaded = false;
    });
    SQLResponse? sqlResponse = await get(); //Get from db
    if (sqlResponse?.status == SQLResponseStatusTypes.success) {
      myPrint(sqlResponse?.toString(extended: false));
      getMarkers();
      resetItemList();
      resetLocationList();
      setState(() {
        noItems = itemsJsonList.isEmpty;
        isLoaded = true;
        _applyItemFilters(notify: false);
      });
    }
    //If there is an error
    else if (sqlResponse?.status != SQLResponseStatusTypes.success ||
        sqlResponse == null) {
      myPrint(sqlResponse);
      setState(() {
        isLoaded = true;
        networkError = true;
      });
    }
  }

  void searchItem(String keyword) {
    _searchQuery = keyword.trim().toLowerCase();
    _applyItemFilters();
  }

  void _applyItemFilters({bool notify = true}) {
    final filtered = itemsJsonList.where((item) {
      final matchesSearch = _searchQuery.isEmpty ||
          (item.name ?? '').toLowerCase().contains(_searchQuery) ||
          (item.location ?? '').toLowerCase().contains(_searchQuery) ||
          item.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));
      final matchesStatus =
          _statusFilter == null || item.status == _statusFilter;
      final matchesTag = _tagFilter == null || item.tags.any(
            (tag) => tag.toLowerCase() == _tagFilter!.toLowerCase(),
          );
      final matchesBin = _binFilter == null || item.binId == _binFilter;
      return matchesSearch && matchesStatus && matchesTag && matchesBin;
    }).toList();

    void update() {
      itemsUpdatingList = filtered;
      viewList = filtered;
      itemsUpdatingListLength = filtered.length;
    }

    if (notify) {
      setState(update);
    } else {
      update();
    }
  }

  Future<void> _showFilters() async {
    ItemStatus? status = _statusFilter;
    String? tag = _tagFilter;
    int? binId = _binFilter;
    final tags = itemsJsonList.expand((item) => item.tags).toSet().toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final bins = [...locationsJsonList]
      ..sort((a, b) => binDisplayPath(a).compareTo(binDisplayPath(b)));

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Header('Filter Items'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ItemStatus?>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: [
                    const DropdownMenuItem<ItemStatus?>(
                      value: null,
                      child: Text('All statuses'),
                    ),
                    ...ItemStatus.values.map(
                      (value) => DropdownMenuItem<ItemStatus?>(
                        value: value,
                        child: Text(value.label),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => status = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: tag,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Tag'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All tags'),
                    ),
                    ...tags.map(
                      (value) => DropdownMenuItem<String?>(
                        value: value,
                        child: Text(value),
                      ),
                    ),
                  ],
                  onChanged: (value) => setDialogState(() => tag = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  value: binId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Bin'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All bins'),
                    ),
                    ...bins.map(
                      (bin) => DropdownMenuItem<int?>(
                        value: bin.id,
                        child: Text(
                          binDisplayPath(bin),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) => setDialogState(() => binId = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _statusFilter = null;
                  _tagFilter = null;
                  _binFilter = null;
                  _applyItemFilters(notify: false);
                });
                Navigator.pop(dialogContext);
              },
              child: const ButtonText('Clear'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _statusFilter = status;
                  _tagFilter = tag;
                  _binFilter = binId;
                  listItems = true;
                  _applyItemFilters(notify: false);
                });
                Navigator.pop(dialogContext);
              },
              child: const ButtonText('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void sortNearMe() {
    LatLng locationInstance = userLocation;
    List<LocationDistance> locationDistances = [];
    for (var i in itemsUpdatingList) {
      final bin = getLocationFromId(i.binId);
      if (bin == null || !(bin.location?.contains(',') ?? false)) {
        continue;
      }
      double latitude = stringToLatLng(bin.location!).latitude;
      double longitude = stringToLatLng(bin.location!).longitude;

      double userLatitude = locationInstance.latitude;
      double userLongitude = locationInstance.longitude;

      double x = sqrt((pow((userLatitude - latitude), 2)) +
          (pow((userLongitude - longitude), 2)));

      locationDistances.add(LocationDistance(item: i, distance: x));
    }
    locationDistances.sort((a, b) => a.distance!.compareTo(b.distance!));
    setState(() {
      itemsUpdatingList = [];
    });
    for (int i = 0; i < locationDistances.length; i++) {
      itemsUpdatingList.add(locationDistances[i].item!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (listItems) {
          setState(() {
            listItems = false;
          });
          return Future.value(listItems);
        } else {
          final value = await confirmExit();
          if (value != null) {
            return Future.value(value);
          } else {
            return Future.value(false);
          }
        }
      },
      child: Scaffold(
        key: scaffoldKey,
        resizeToAvoidBottomInset: false,
        drawer: const HomeDrawer(),
        extendBody: true,
        body: Container(
          color: backgroundColor,
          child: Column(
            children: [
              Container(
                color: Colors.black,
                height:
                    screenHeight(context) - screenHeightWithSafeArea(context),
              ),
              SizedBox(
                  height: screenHeightWithSafeArea(context),
                  width: screenWidth(context),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          height: screenHeight(context) / 10,
                          width: screenWidth(context),
                          decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                  colors: [Colors.black, Colors.transparent],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter)),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: screenHeight(context) / 10,
                          width: screenWidth(context),
                          decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                  colors: [Colors.transparent, Colors.black],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter)),
                        ),
                      ),
                      Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                        left: screenWidth(context) / 21,
                                        top: screenWidth(context) / 26),
                                    child: Icon(
                                      Icons.menu,
                                      size: screenHeight(context) / 25,
                                    ),
                                  ),
                                  Stack(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(
                                            left: screenWidth(context) / 35,
                                            top: screenWidth(context) / 48),
                                        child: MyStuffLogo(size: 8),
                                      ),
                                      FilledButton(
                                          style: ButtonStyle(
                                              foregroundColor:
                                                  MaterialStateProperty.all(
                                                      Colors.transparent),
                                              backgroundColor:
                                                  MaterialStateProperty.all(
                                                      Colors.transparent)),
                                          onPressed: () {
                                            if (listItems) {
                                              setState(() {
                                                FocusManager
                                                    .instance.primaryFocus
                                                    ?.unfocus();
                                                listItems = false;
                                              });
                                            } else {
                                              scaffoldKey.currentState
                                                  ?.openDrawer();
                                            }
                                          },
                                          child: const Icon(Icons.add)),
                                    ],
                                  ).animate(target: listItems ? 1 : 0).fadeIn(),
                                ],
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                    top: screenHeight(context) / 80),
                                child: SizedBox(
                                  width: screenWidth(context) / 1.25,
                                  height: screenHeight(context) / 18,
                                  child: SearchBar(
                                    controller: searchController,
                                    hintText: "Search",
                                    onTap: () => setState(() {
                                      _applyItemFilters(notify: false);
                                      listItems = true;
                                    }),
                                    onChanged: (value) => {
                                      searchItem(value),
                                      setState(() {
                                        listItems = true;
                                      })
                                    },
                                    leading: const Icon(Icons.search),
                                    trailing: [
                                      IconButton(
                                        tooltip: 'Add item',
                                        onPressed: !networkError && isLoaded
                                            ? addItem
                                            : null,
                                        icon: const Icon(Icons.add),
                                      ),
                                      IconButton(
                                        tooltip: 'Filter items',
                                        onPressed: _showFilters,
                                        icon: Icon(
                                          Icons.filter_alt_outlined,
                                          color: _statusFilter != null ||
                                                  _tagFilter != null ||
                                                  _binFilter != null
                                              ? Colors.amber
                                              : null,
                                        ),
                                      ),
                                      PopupMenuButton<SortValue>(
                                        onOpened: () {
                                          if (!listItems) {
                                            setState(() {
                                              listItems = true;
                                            });
                                          }
                                        },
                                        initialValue: sortValue,
                                        icon: const Icon(Icons.sort_outlined),
                                        onSelected: (SortValue item) {
                                          setState(() {
                                            sortValue = item;
                                          });
                                          if (item == SortValue.dateSaved) {
                                            itemsUpdatingList.sort((a, b) => a
                                                .storeDate!
                                                .compareTo(b.storeDate!));
                                            setState(() {
                                              itemsUpdatingList =
                                                  itemsUpdatingList.reversed
                                                      .toList();
                                            });
                                          } else if (item == SortValue.name) {
                                            itemsUpdatingList.sort((a, b) =>
                                                a.name!.compareTo(b.name!));
                                          } else if (item == SortValue.nearMe) {
                                            sortNearMe();
                                          }
                                        },
                                        itemBuilder: (BuildContext context) =>
                                            <PopupMenuEntry<SortValue>>[
                                          const PopupMenuItem<SortValue>(
                                            value: SortValue.dateSaved,
                                            child: Text('Date Saved'),
                                          ),
                                          const PopupMenuItem<SortValue>(
                                            value: SortValue.name,
                                            child: Text('Name'),
                                          ),
                                          const PopupMenuItem<SortValue>(
                                            value: SortValue.nearMe,
                                            child: Text('Near me'),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                          onPressed: () async {
                                            if (!networkError) {
                                              if (isLoaded) {
                                                if (userLocation ==
                                                    const LatLng(0, 0)) {
                                                  setState(() {
                                                    processing = true;
                                                  });
                                                  LocationData locationData =
                                                      await gvLocation
                                                          .getLocation();
                                                  setState(() {
                                                    userLocation = LatLng(
                                                        locationData.latitude!,
                                                        locationData
                                                            .longitude!);
                                                  });
                                                  showAllMarkers(false);
                                                } else {
                                                  showAllMarkers(true);
                                                }
                                                setState(() {
                                                  itemsUpdatingList =
                                                      itemsJsonList;
                                                  listItems = false;
                                                  listLocations = false;
                                                  processing = false;
                                                });
                                                Get.to(() => ItemLocationScreen(
                                                    withTarget: true));
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(const SnackBar(
                                                        content: BodyText(
                                                            'Items still loading...')));
                                              }
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(const SnackBar(
                                                      content: BodyText(
                                                          'Network Error...')));
                                            }
                                          },
                                          icon: const Icon(
                                              FontAwesomeIcons.mapLocationDot))
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          !listItems
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: screenHeight(context) / 10,
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: screenHeight(context) / 50),
                                      child: MyStuffLogo(
                                        size: 2.25,
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        FloatingActionButton.extended(
                                            onPressed: !networkError && isLoaded
                                                ? addItem
                                                : null,
                                            heroTag: 'add-item',
                                            icon: Icon(Icons.add,
                                                color: inverseColor(context)),
                                            label:
                                                const ButtonText('Add Item')),
                                        if (User.user.isAdmin ||
                                            editableBins().isNotEmpty) ...[
                                          SizedBox(
                                            width: screenWidth(context) / 50,
                                          ),
                                          FloatingActionButton.extended(
                                            onPressed: addBin,
                                            heroTag: 'add-bin',
                                            icon: Icon(
                                              Icons.add_location_alt,
                                              color: inverseColor(context),
                                            ),
                                            label: const ButtonText('Add Bin'),
                                          ),
                                        ],
                                        IconButton(
                                            onPressed: () {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(const SnackBar(
                                                      content: BodyText(
                                                          'Reloading Data...')));
                                              getData();
                                              if (networkError) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(const SnackBar(
                                                        content: BodyText(
                                                            'Network Error...')));
                                              }
                                            },
                                            icon: const Icon(
                                                Icons.refresh_outlined))
                                      ],
                                    ),
                                    SizedBox(
                                      height: screenHeight(context) / 50,
                                    ),
                                    FloatingActionButton.extended(
                                      onPressed: () async {
                                        if (!networkError) {
                                          if (isLoaded) {
                                            if (userLocation ==
                                                const LatLng(0, 0)) {
                                              setState(() {
                                                processing = true;
                                              });
                                              LocationData locationData =
                                                  await gvLocation
                                                      .getLocation();
                                              setState(() {
                                                userLocation = LatLng(
                                                    locationData.latitude!,
                                                    locationData.longitude!);
                                              });
                                            }
                                            setState(() {
                                              listLocations = true;
                                              processing = false;
                                            });
                                            Get.to(() => ItemLocationScreen(
                                                withTarget: false));
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: BodyText(
                                                        'Items still loading...')));
                                          }
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: BodyText(
                                                      'Network Error...')));
                                        }
                                      },
                                      heroTag: 'view-locations',
                                      label: const ButtonText('View Bins'),
                                      icon: Icon(
                                        Icons.location_on,
                                        color: inverseColor(context),
                                      ),
                                    ),
                                  ],
                                )
                              : SizedBox(
                                  height: screenHeight(context) / 1.15,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 25),
                                    child: networkError
                                        ? const Center(child: MyNetworkError())
                                        : noItems
                                            ? Center(
                                                child: ElevatedButton(
                                                    onPressed:
                                                        isLoaded ? addItem : null,
                                                    child: const ButtonText(
                                                        'Add Item')))
                                            : isLoaded &&
                                                    itemsUpdatingList.isEmpty
                                                ? Center(
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const BodyText(
                                                          'No items match these filters.',
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        TextButton(
                                                          onPressed: () {
                                                            searchController
                                                                .clear();
                                                            setState(() {
                                                              _searchQuery = '';
                                                              _statusFilter =
                                                                  null;
                                                              _tagFilter = null;
                                                              _binFilter = null;
                                                              _applyItemFilters(
                                                                notify: false,
                                                              );
                                                            });
                                                          },
                                                          child: const ButtonText(
                                                            'Clear filters',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                : isLoaded
                                                ? ListView.builder(
                                                    itemBuilder:
                                                        (context, index) {
                                                      return Card(
                                                        shadowColor:
                                                            Colors.white,
                                                        elevation: 2,
                                                        color: primaryColor(
                                                            context),
                                                        clipBehavior: Clip.none,
                                                        child: ListTile(
                                                          dense: true,
                                                          visualDensity:
                                                              const VisualDensity(
                                                                  vertical: 4),
                                                          onTap: () {
                                                            viewItem(
                                                              id: itemsUpdatingList[
                                                                      index]
                                                                  .id!,
                                                              locationId:
                                                                  itemsUpdatingList[
                                                                              index]
                                                                          .binId ??
                                                                      0,
                                                              name:
                                                                  itemsUpdatingList[
                                                                          index]
                                                                      .name!,
                                                              location:
                                                                  itemsUpdatingList[
                                                                          index]
                                                                      .location!,
                                                              multiple:
                                                                  itemsUpdatingList[
                                                                          index]
                                                                      .multiple!,
                                                              quantity:
                                                                  itemsUpdatingList[
                                                                          index]
                                                                      .quantity!,
                                                              description:
                                                                  itemsUpdatingList[
                                                                          index]
                                                                      .description!,
                                                              tags:
                                                                  itemsUpdatingList[
                                                                          index]
                                                                      .tags,
                                                            );
                                                          },
                                                          trailing: itemsUpdatingList[
                                                                          index]
                                                                      .image ==
                                                                  null ||
                                                                  itemsUpdatingList[
                                                                          index]
                                                                      .image!
                                                                      .isEmpty
                                                              ? const Icon(Icons
                                                                  .image_not_supported_outlined)
                                                              : CachedNetworkImage(
                                                                  height: 60,
                                                                  width: 60,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  imageUrl:
                                                                      "${Urls.baseUrl}/${itemsUpdatingList[index].image}",
                                                                  errorWidget: (_,
                                                                          __,
                                                                          ___) =>
                                                                      const Icon(
                                                                          Icons
                                                                              .image_not_supported),
                                                                ),
                                                          title: Row(
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                    itemsUpdatingList[
                                                                            index]
                                                                        .name!,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    softWrap:
                                                                        false,
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            screenWidth(context) /
                                                                                35)),
                                                              ),
                                                            ],
                                                          ),
                                                          subtitle: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                getLocationFromId(itemsUpdatingList[index].binId) ==
                                                                        null
                                                                    ? itemsUpdatingList[index]
                                                                            .location ??
                                                                        ''
                                                                    : binDisplayPath(getLocationFromId(itemsUpdatingList[index]
                                                                        .binId)!),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                maxLines: 1,
                                                                style: TextStyle(
                                                                    fontSize: (screenWidth(context) /
                                                                            40)
                                                                        .clamp(
                                                                            12.0,
                                                                            16.0)
                                                                        .toDouble()),
                                                              ),
                                                              Text(
                                                                itemsUpdatingList[
                                                                        index]
                                                                    .status
                                                                    .label,
                                                                style: TextStyle(
                                                                  color: itemsUpdatingList[
                                                                          index]
                                                                      .status
                                                                      .color,
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                ),
                                                              ),
                                                              if (itemsUpdatingList[
                                                                      index]
                                                                  .tags
                                                                  .isNotEmpty)
                                                                Text(
                                                                  itemsUpdatingList[
                                                                          index]
                                                                      .tags
                                                                      .take(3)
                                                                      .join(' • '),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  maxLines: 1,
                                                                  style: TextStyle(
                                                                    color: middleGrey(
                                                                        context),
                                                                    fontSize: 12,
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    itemCount:
                                                        itemsUpdatingListLength,
                                                  )
                                                : const Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                            color:
                                                                Colors.white)),
                                  )
                                      .animate(target: !listItems ? 0 : 1)
                                      .fadeIn())
                        ],
                      ),
                      Align(
                        alignment: Alignment.center,
                      )
                          .animate(target: !listItems ? 0 : 1)
                          .moveX(end: screenWidth(context) / 10.9714285714)
                          .moveY(
                              begin: screenWidth(context) / -6.98181818182,
                              end: screenWidth(context) / -1.08169014085),
                      processing
                          ? Container(
                              height: screenHeightWithSafeArea(context),
                              color: const Color(0xAA000000),
                              width: screenWidth(context),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                      color: Colors.white),
                                  SubHeader('Loading...')
                                ],
                              ),
                            )
                          : Container(),
                      myPrintBool
                          ? Align(
                              alignment: Alignment.bottomRight,
                              child: BodyText(
                                  "Dev Version: ${AppDetails.version}"))
                          : Container()
                    ],
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
