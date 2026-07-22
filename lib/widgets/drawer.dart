import 'package:cached_network_image/cached_network_image.dart';
import 'package:dad_app/models/user_model.dart';
import 'package:dad_app/pages/profile_page.dart';
import 'package:dad_app/pages/settings/notifications_page.dart';
import 'package:dad_app/pages/sign_up_or_log_in_page.dart';
import 'package:dad_app/widgets/text.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart' hide FormData, Response;
import 'package:dad_app/utils/constants.dart';
import 'package:dad_app/utils/init.dart';
import 'package:dad_app/styles/themes.dart';
import 'package:dad_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/location_model.dart';
import '../models/item_model.dart';
import '../models/response_model.dart';
import '../pages/new_update_page.dart';

class HomeDrawer extends StatefulWidget {
  const HomeDrawer({super.key});

  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  TextEditingController emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    setState(() {});
    super.initState();
  }

  Future emailInUseError() => showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: const SubHeader('Error'),
            content: SubHeader('${emailController.text}\nalready in use'),
            actions: [
              ElevatedButton(
                  onPressed: () => {Navigator.pop(context)},
                  child: const ButtonText('Okay'))
            ],
          ));

  Future logOutWarning() => showDialog(
      context: context,
      builder: (context) => AlertDialog(
            icon: const Icon(
              Icons.warning,
              color: Colors.yellow,
            ),
            title: const Text('Are you sure?'),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  clearData();
                  Get.offAll(() => const SignUpOrLogInPage());
                  preferences.remove('user');
                  preferences
                      .setStringList('settings', <String>['false', 'false']);
                },
                child: Text('Yes',
                    style: TextStyle(
                        color: inverseColor(context),
                        fontWeight: FontWeight.w300)),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                },
                child: Text('No',
                    style: TextStyle(
                        color: inverseColor(context),
                        fontWeight: FontWeight.w300)),
              ),
            ],
          ));

  Future sendFeedback() => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Send feedback:'),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final url = Uri.parse('sms:${AppDetails.myNumber}');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                } else {
                  throw 'Could not launch $url';
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: [
                  const Icon(Icons.sms),
                  Text('SMS us',
                      style: TextStyle(
                          color: inverseColor(context),
                          fontWeight: FontWeight.w300))
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final url = Uri.parse(
                    'mailto:${AppDetails.myEmail}?subject=MyStuff Feedback');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                } else {
                  throw 'Could not launch $url';
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: [
                  const Icon(Icons.email),
                  Text('Email us',
                      style: TextStyle(
                          color: inverseColor(context),
                          fontWeight: FontWeight.w300))
                ],
              ),
            ),
          ],
        ),
      );

  Future newUpdate() => showDialog(
      context: context,
      builder: (context) => const AlertDialog(content: NewUpdatePage()));

  Future addEmail() => showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: const Text('Add Email'),
            content: Form(
                key: formKey,
                child: TextFormField(
                  controller: emailController,
                  validator: (val) {
                    if (val!.isEmpty) {
                      return InputErrors.emptyEmail;
                    } else {
                      if (!InputErrors.emailChars.hasMatch(val)) {
                        return InputErrors.emailError;
                      } else {
                        return null;
                      }
                    }
                  },
                  keyboardType: TextInputType.emailAddress,
                  textAlignVertical: TextAlignVertical.center,
                  decoration:
                      const InputDecoration(suffixIcon: Icon(Icons.email)),
                )),
            actions: [
              ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      User putUser = User(
                          userid: User.user.userid!,
                          name: User.user.name!,
                          email: emailController.text,
                          password: User.user.password);

                      List? email = await putUser.verifyEmail();
                      if (email != null) {
                        bool emailExist = email[0];
                        if (emailExist) {
                          emailInUseError();
                        } else if (!emailExist && email[1] == null) {
                          SQLResponse? sqlPut = await putUser.put();
                          myPrint(User.user);
                          setState(() {});
                          preferences.setString(
                              'user', userToJson([User.user]));
                          Navigator.pop(context);
                        }
                      }
                    }
                  },
                  child: Text(
                    'Add Email',
                    style: TextStyle(color: inverseColor(context)),
                  )),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel',
                      style: TextStyle(color: inverseColor(context)))),
            ],
          ));

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: screenHeightWithSafeArea(context) / 20,
          horizontal: screenWidth(context) / 25,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: screenWidth(context) / 7.9,
                  backgroundColor: inverseColor(context),
                  child: CircleAvatar(
                      backgroundColor: primaryColor(context),
                      radius: screenWidth(context) / 8,
                      child: Icon(
                        Icons.person,
                        size: screenWidth(context) / 5,
                        color: inverseColor(context),
                      )),
                ),
                SubHeader(User.user.name!),
                hasEmailBool
                    ? BodyText(User.user.email!)
                    : FloatingActionButton.extended(
                        onPressed: () {
                          addEmail();
                        },
                        label: const ButtonText('Add Email'),
                        icon: const Icon(
                          Icons.warning,
                          color: Colors.yellow,
                        ),
                      ),
                BodyText(User.user.userid!),
                Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: screenHeight(context) / 500),
                    child: const Divider()),
                ElevatedButton(
                  onPressed: () {
                    Get.to(() => const ProfilePage());
                  },
                  style: ButtonStyle(
                      shadowColor: MaterialStateProperty.all(Colors.white)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const Icon(Icons.person),
                      Text('Profile',
                          style: TextStyle(
                              color: inverseColor(context),
                              fontWeight: FontWeight.w300))
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Get.to(() => const NotificationsPage());
                  },
                  style: ButtonStyle(
                      shadowColor: MaterialStateProperty.all(Colors.white)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const Icon(Icons.notifications),
                      Text('Notifications',
                          style: TextStyle(
                              color: inverseColor(context),
                              fontWeight: FontWeight.w300))
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: sendFeedback,
                  style: ButtonStyle(
                      shadowColor: MaterialStateProperty.all(Colors.white)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const Icon(Icons.feedback),
                      Text('Feedback',
                          style: TextStyle(
                              color: inverseColor(context),
                              fontWeight: FontWeight.w300))
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Get.to(() => const NewUpdatePage());
                  },
                  style: ButtonStyle(
                      shadowColor: MaterialStateProperty.all(Colors.white)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const Icon(Icons.update),
                      Text('Changelog',
                          style: TextStyle(
                              color: inverseColor(context),
                              fontWeight: FontWeight.w300))
                    ],
                  ),
                ),
                Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: screenHeight(context) / 500),
                    child: const Divider()),
                ElevatedButton(
                  onPressed: () {
                    logOutWarning();
                  },
                  style: ButtonStyle(
                      shadowColor: MaterialStateProperty.all(Colors.white)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const Icon(Icons.logout),
                      Text('Log Out',
                          style: TextStyle(
                              color: inverseColor(context),
                              fontWeight: FontWeight.w300))
                    ],
                  ),
                ),
              ],
            ),
            Align(
                alignment: Alignment.centerRight,
                child: Text('Version: ${AppDetails.version}'))
          ],
        ),
      ),
    );
  }
}

class LocationDrawer extends StatefulWidget {
  const LocationDrawer({super.key});

  @override
  State<LocationDrawer> createState() => _LocationDrawerState();
}

class _LocationDrawerState extends State<LocationDrawer> {
  List<Item> viewItemList = [];
  List<Location> viewLocationList = [];
  final formKeyTwo = GlobalKey<FormState>();

  final newLocationController = TextEditingController();
  Color pickerColor = const Color(0xff443a49);
  Color pickedColor = Colors.red;
  Set<Marker> dummyObject = {};
  String newLocationName = '';
  LatLng currentLocationInstance = const LatLng(0, 0);

  void searchItem(keyword) async {
    if (keyword.isEmpty) {
      listLocations ? resetLocationList() : resetItemList();
    } else {
      itemsUpdatingList = [];
      locationsUpdatingList = [];
      if (listLocations) {
        for (var i = 0; i < locationsJsonList.length; i++) {
          bool found = locationsJsonList[i]
              .name!
              .toLowerCase()
              .contains(keyword.toLowerCase());
          if (found) {
            locationsUpdatingList.add(locationsJsonList[i]);
          }
        }
      } else {
        for (var i = 0; i < itemsJsonList.length; i++) {
          bool found = itemsJsonList[i]
                  .name!
                  .toLowerCase()
                  .contains(keyword.toLowerCase()) ||
              itemsJsonList[i]
                  .location!
                  .toLowerCase()
                  .contains(keyword.toLowerCase());
          if (found) {
            itemsUpdatingList.add(itemsJsonList[i]);
          }
        }
      }
    }
    setState(() {
      itemsUpdatingListLength = itemsUpdatingList.length;
      locationsUpdatingListLength = locationsUpdatingList.length;
      viewLocationList = locationsUpdatingList;
      viewItemList = itemsUpdatingList;
    });
  }

  Future colorPicker() => showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: const Text('Pick a location color'),
            content: ColorPicker(
                pickerColor: pickerColor,
                onColorChanged: (Color color) {
                  setState(() {
                    pickerColor = color;
                  });
                }),
            actions: [
              ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      pickedColor = pickerColor;
                    });
                    Navigator.pop(context);
                  },
                  child: const ButtonText("Choose color"))
            ],
          ));

  Future newLocation() => showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: const Text('New Location'),
            content: Form(
              key: formKeyTwo,
              child: TextFormField(
                validator: (value) {
                  if (value == '') {
                    return 'Cannot be empty';
                  }
                  bool x = false;
                  for (var i = 0; i < locationsJsonList.length; i++) {
                    if (value?.toLowerCase() ==
                        locationsJsonList[i].name!.toLowerCase()) {
                      setState(() {
                        x = true;
                      });
                      break;
                    }
                  }
                  if (x) {
                    return '$value already exists. Try another name';
                  } else {
                    return null;
                  }
                },
                controller: newLocationController,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                      vertical: screenHeight(context) / 100,
                      horizontal: screenWidth(context) / 100),
                ),
              ),
            ),
            actions: [
              ElevatedButton(
                  onPressed: () async {
                    if (formKeyTwo.currentState!.validate()) {
                      await colorPicker();
                      setState(() {
                        newLocationName = newLocationController.text;
                      });
                      getMarkers();
                      resetLocationList();
                      Navigator.pop(context);
                    }
                  },
                  child: const ButtonText("Add"))
            ],
          ));

  Future updateLocation({required String name, required int locationId}) =>
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Header('Update $name'),
                content: const _UpdateLocation(),
                actions: [
                  ElevatedButton(
                      onPressed: () async {
                        Location newLocation = Location(
                          id: locationId,
                          name: _updateLocationController.text,
                          color: colorToString(_pickedColor),
                          location: '',
                        );
                        SQLResponse? sqlPut = await newLocation.put(name);
                        myPrint(sqlPut);
                        setState(() {});
                        Navigator.pop(context);
                      },
                      child: const ButtonText('Update')),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const ButtonText('Cancel'))
                ],
                backgroundColor: primaryColor(context),
              ));

  Future deleteLocation({required String name, required int locationId}) =>
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Header("Delete $name?"),
                content: const _DeleteLocation(),
                actions: [
                  ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          processing = true;
                        });

                        // Delete and set new location
                        if (_deleteOption == 'Assign items to new location') {
                          await newLocation();
                          Location dropNewLocation = Location(
                              id: locationId,
                              name: newLocationName,
                              location: latLngToString(currentLocationInstance),
                              color: colorToString(pickedColor));
                          await dropNewLocation.drop(
                              allItems: false, oldName: name);
                          setState(() {});
                          // Delete along with all locations.
                        } else {
                          Location dropAllLocation = Location(
                              id: locationId,
                              name: newLocationName,
                              color: '',
                              location: '');
                          await dropAllLocation.drop(allItems: true);
                          setState(() {});
                        }
                        setState(() {
                          processing = false;
                        });
                        Navigator.pop(context);
                      },
                      child: const ButtonText('Delete')),
                ],
                backgroundColor: primaryColor(context),
              ));

  Future editLocation({required String name, required int locationId}) =>
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Header(name),
                actions: [
                  ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          _pickedColor = stringToColor(locationsJsonList[
                                  getLocationIndexFromId(locationId)]
                              .color!);
                        });
                        await updateLocation(
                            name: name, locationId: locationId);
                        Navigator.pop(context);
                      },
                      child: const ButtonText('Update')),
                  ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          currentLocationInstance = userLocation;
                        });
                        await deleteLocation(
                            name: name, locationId: locationId);
                        Navigator.pop(context);
                      },
                      child: const ButtonText('Delete')),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const ButtonText('Cancel'))
                ],
                backgroundColor: primaryColor(context),
              ));

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: screenHeightWithSafeArea(context) / 20,
            horizontal: screenWidth(context) / 25,
          ),
          child: Column(
            children: [
              SizedBox(
                width: screenWidth(context) / 2,
                child: TextFormField(
                  controller: searchController,
                  keyboardType: TextInputType.name,
                  textAlignVertical: TextAlignVertical.center,
                  onTap: () => setState(() {
                    resetItemList();
                  }),
                  onEditingComplete: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  onTapOutside: (event) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  onChanged: (value) => {searchItem(value)},
                  decoration: const InputDecoration(
                      hintText: "Search for item",
                      suffixIcon: Icon(Icons.search)),
                ),
              ),
              SizedBox(
                  height: screenHeight(context) / 1.185,
                  child: ListView.builder(
                    itemBuilder: (context, index) {
                      return listLocations
                          ? Card(
                              shadowColor: Colors.white,
                              elevation: 2,
                              color: primaryColor(context),
                              clipBehavior: Clip.none,
                              child: ListTile(
                                dense: true,
                                visualDensity: const VisualDensity(vertical: 0),
                                title: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                          locationsUpdatingList[index].name!,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: false,
                                          style: TextStyle(
                                              fontSize:
                                                  (screenWidth(context) / 35))),
                                    )
                                  ],
                                ),
                                trailing: Icon(
                                  Icons.location_on,
                                  color: stringToColor(
                                      locationsUpdatingList[index].color!),
                                ),
                                onTap: () async {
                                  GoogleMapController controller =
                                      await googleMapsController.future;
                                  controller.animateCamera(CameraUpdate
                                      .newCameraPosition(CameraPosition(
                                          target: stringToLatLng(
                                              locationsUpdatingList[index]
                                                  .location!),
                                          zoom: cameraZoom >= 14
                                              ? cameraZoom
                                              : 14)));
                                  Navigator.pop(context);
                                },
                                subtitle: Text('Hold to edit',
                                    style: TextStyle(
                                        fontSize: screenWidth(context) / 40)),
                                onLongPress: () {
                                  editLocation(
                                      name: locationsUpdatingList[index].name!,
                                      locationId:
                                          locationsUpdatingList[index].id!);
                                },
                              ),
                            )
                          : Card(
                              shadowColor: Colors.white,
                              elevation: 2,
                              color: primaryColor(context),
                              clipBehavior: Clip.none,
                              child: ListTile(
                                dense: true,
                                visualDensity: const VisualDensity(vertical: 0),
                                onTap: () async {
                                  GoogleMapController controller =
                                      await googleMapsController.future;
                                  controller.animateCamera(CameraUpdate
                                      .newCameraPosition(CameraPosition(
                                          target: stringToLatLng(
                                              locationsUpdatingList[
                                                      getLocationIndexFromId(
                                                          getLocationIdFromName(
                                                              itemsUpdatingList[
                                                                      index]
                                                                  .location!))]
                                                  .location!),
                                          zoom: cameraZoom >= 14
                                              ? cameraZoom
                                              : 14)));
                                  Navigator.pop(context);
                                },
                                trailing: CachedNetworkImage(
                                  height: 60,
                                  width: 60,
                                  fit: BoxFit.cover,
                                  imageUrl:
                                      "${Urls.baseUrl}/${itemsUpdatingList[index].image}",
                                  progressIndicatorBuilder:
                                      (context, url, downloadProgress) =>
                                          CircularProgressIndicator(
                                              value: downloadProgress.progress),
                                  errorWidget: (context, url, error) {
                                    myPrint(error);
                                    return Image.file(
                                      file,
                                      fit: BoxFit.contain,
                                      height: screenHeight(context) / 20,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        myPrint(error);
                                        return const Icon(
                                            Icons.image_not_supported);
                                      },
                                    );
                                  },
                                ),
                                title: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                          itemsUpdatingList[index].name!,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: false,
                                          style: TextStyle(
                                              fontSize:
                                                  (screenWidth(context) / 35))),
                                    ),
                                  ],
                                ),
                                subtitle: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                          itemsUpdatingList[index].location!,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: false,
                                          style: TextStyle(
                                              fontSize:
                                                  screenWidth(context) / 40)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                    },
                    itemCount: listLocations
                        ? locationsUpdatingListLength
                        : itemsUpdatingListLength,
                  ))
            ],
          )),
    );
  }
}

Color _pickedColor = Colors.red;

class _UpdateLocation extends StatefulWidget {
  const _UpdateLocation();

  @override
  State<_UpdateLocation> createState() => _UpdateLocationState();
}

final _updateLocationController = TextEditingController();

class _UpdateLocationState extends State<_UpdateLocation> {
  Color pickerColor = const Color(0xff443a49);

  Future colorPicker() => showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: const Header('Pick a location color'),
            content: ColorPicker(
                enableAlpha: false,
                displayThumbColor: false,
                hexInputBar: false,
                pickerColor: pickerColor,
                onColorChanged: (Color color) {
                  setState(() {
                    pickerColor = color;
                  });
                }),
            actions: [
              ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _pickedColor = pickerColor;
                    });
                    Navigator.pop(context);
                  },
                  child: const ButtonText("Choose color"))
            ],
          ));

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          TextFormField(
              decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                      vertical: screenHeight(context) / 100)),
              controller: _updateLocationController),
          SizedBox(
            height: screenHeight(context) / 40,
          ),
          Row(
            children: [
              FloatingActionButton.small(
                  backgroundColor: _pickedColor, onPressed: colorPicker),
              const BodyText('Change Color'),
            ],
          ),
        ]);
  }
}

String _deleteOption = 'Delete along with items';

class _DeleteLocation extends StatefulWidget {
  const _DeleteLocation();

  @override
  State<_DeleteLocation> createState() => _DeleteLocationState();
}

class _DeleteLocationState extends State<_DeleteLocation> {
  List<String> deleteOptions = [
    'Delete along with items',
    'Assign items to new location'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubHeader('Options:'),
        DropdownButton(
          value: _deleteOption,
          items: deleteOptions.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: BodyText(value),
            );
          }).toList(),
          onChanged: (String? val) {
            setState(() {
              _deleteOption = val!;
            });
          },
        )
      ],
    );
  }
}
