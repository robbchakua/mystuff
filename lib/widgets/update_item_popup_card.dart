import 'package:dad_app/utils/utils.dart';
import 'package:dad_app/widgets/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/location_model.dart';
import '../models/item_model.dart';
import '../models/response_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import '../utils/init.dart';
import '../styles/themes.dart';

class UpdateItemColumn extends StatefulWidget {
  final int id;
  final String? name;
  final String? location;
  final bool? multiple;
  final int? quantity;
  final String? description;
  final String? oldImage;

  UpdateItemColumn(
      {super.key,
      required this.id,
      this.name,
      this.location,
      this.multiple,
      this.quantity,
      this.description,
      this.oldImage});

  @override
  State<UpdateItemColumn> createState() => UpdateItemColumnState(
      id: id,
      name: name,
      location: location,
      multiple: multiple,
      quantity: quantity,
      description: description,
      oldImage: oldImage);
}

class UpdateItemColumnState extends State<UpdateItemColumn> {
  late int id;
  late String? name;
  late String? location;
  late bool? multiple;
  late int? quantity;
  late String? description;
  late String? oldImage;

  UpdateItemColumnState(
      {required this.id,
      this.name,
      this.location,
      this.multiple,
      this.quantity,
      this.description,
      this.oldImage});

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final quantityController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final formKeyTwo = GlobalKey<FormState>();

  Color pickerColor = const Color(0xff443a49);
  Color pickedColor = Colors.red;
  final newLocationController = TextEditingController();

  DateTime selectedDate = timeNow;
  String locationNameValue = '';
  bool createdNewLocation = false;
  bool multipleBool = false;
  LatLng currentLocationInstance = userLocation;
  int numOfLocationsBeforeAdd = locationsCloseToUserList.length;

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
                  onPressed: () {
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
                  if (value == '' || value == null || value == ' ') {
                    return 'Cannot be empty';
                  }
                  bool x = false;
                  for (var i = 0; i < locationsJsonList.length; i++) {
                    if (value.toLowerCase().trim() ==
                        locationsJsonList[i].name!.toLowerCase().trim()) {
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
                    LatLng currentLocationInstance = userLocation;
                    if (formKeyTwo.currentState!.validate()) {
                      await colorPicker();
                      setState(() {
                        locationNameValue = newLocationController.text;
                        markers = {};
                        createdNewLocation = true;
                        locationsJsonList.add(Location(
                            id: nextLocationId(),
                            userid: User.user.userid,
                            name: newLocationController.text.trim(),
                            color: pickedColor.value
                                .toRadixString(16)
                                .toUpperCase()
                                .substring(2),
                            location:
                                "${currentLocationInstance.latitude},${currentLocationInstance.longitude}"));
                      });
                      locationsCloseToUserList
                          .add(newLocationController.text.trim());

                      getMarkers();
                      resetItemList();
                      resetLocationList();
                      Navigator.pop(context);
                    }
                  },
                  child: const ButtonText("Add"))
            ],
          ));

  @override
  void initState() {
    setState(() {
      if (multiple!) {
        multipleBool = true;
      }
      if (locationCloseToUser) {
        locationNameValue = locationsCloseToUserList[0];
      } else {
        locationNameValue = '';
      }
      nameController.text = name!;
      descriptionController.text = description!;
      quantityController.text = quantity.toString();
    });
    super.initState();
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Form(
      key: formKey,
      child: Column(children: [
        Padding(
            padding: EdgeInsets.all(screenWidth(context) / 50),
            child: const Header("Update Item")),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextFormField(
            validator: (value) {
              if (value!.isEmpty) {
                return InputErrors.empty;
              } else {
                return null;
              }
            },
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Name',
              contentPadding: EdgeInsets.symmetric(
                  vertical: screenHeight(context) / 100,
                  horizontal: screenWidth(context) / 100),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
              decoration: BoxDecoration(
                  color: secondaryColor(context),
                  border: Border.all(color: inverseColor(context))),
              width: screenWidth(context) / 1.4,
              height: screenWidth(context) / 1.4,
              child: Image.file(
                file,
                fit: BoxFit.contain,
                height: screenHeight(context) / 20,
                errorBuilder: (context, error, stackTrace) {
                  myPrint(error);
                  return const Icon(Icons.image_not_supported);
                },
              )),
        ),
        Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              validator: (value) {
                if (value!.isEmpty) {
                  return InputErrors.empty;
                } else {
                  return null;
                }
              },
              keyboardType: TextInputType.multiline,
              maxLines: null,
              minLines: 5,
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                contentPadding: EdgeInsets.symmetric(
                    horizontal: screenWidth(context) / 100,
                    vertical: screenHeight(context) / 80),
              ),
            )),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
                padding: EdgeInsets.all(screenWidth(context) / 150),
                child: SubHeader(locationCloseToUser
                    ? 'Location(s) \nnear you:'
                    : !createdNewLocation
                        ? 'Your \nLocations are \nnot near you:'
                        : 'Your new location:\n$locationNameValue')),
            locationCloseToUser
                ? Row(
                    children: [
                      IconButton(
                          onPressed: newLocation, icon: const Icon(Icons.add)),
                      Padding(
                          padding: EdgeInsets.all(screenWidth(context) / 150),
                          child: DropdownButton(
                            value: locationNameValue,
                            items: locationsCloseToUserList
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: BodyText(value),
                              );
                            }).toList(),
                            onChanged: (String? val) {
                              setState(() {
                                locationNameValue = val!;
                              });
                            },
                          )),
                      CircleAvatar(
                          backgroundColor: stringToColor(locationsJsonList[
                                  getLocationIndexFromId(
                                      getLocationIdFromName(locationNameValue))]
                              .color!),
                          radius: screenWidth(context) / 30),
                    ],
                  )
                : !createdNewLocation
                    ? TextButton(
                        onPressed: newLocation,
                        child: const ButtonText('New Location'))
                    : Row(
                        children: [
                          CircleAvatar(
                              backgroundColor: pickedColor,
                              radius: screenWidth(context) / 30),
                          IconButton(
                              onPressed: newLocation,
                              icon: const Icon(Icons.edit)),
                        ],
                      )
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
                padding: EdgeInsets.all(screenWidth(context) / 150),
                child: const SubHeader('Multiple Items')),
            Padding(
                padding: EdgeInsets.all(screenWidth(context) / 150),
                child: Switch(
                  value: multipleBool,
                  onChanged: (value) {
                    setState(() {
                      multipleBool = value;
                    });
                  },
                )),
          ],
        ),
        Padding(
          padding: EdgeInsets.all(screenWidth(context) / 150),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SubHeader('Number of Items'),
              SizedBox(
                width: screenWidth(context) / 4,
                child: Padding(
                    padding: EdgeInsets.all(screenWidth(context) / 150),
                    child: TextFormField(
                        readOnly: !multipleBool,
                        keyboardType: TextInputType.number,
                        controller: quantityController,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              vertical: screenHeight(context) / 100,
                              horizontal: screenWidth(context) / 100),
                          filled: true,
                        ))),
              ),
            ],
          ).animate(target: multipleBool ? 0 : 1).fadeOut(),
        ),
        const Divider(),
        Row(
          children: [
            Padding(
              padding: EdgeInsets.all(screenWidth(context) / 100),
              child: ElevatedButton(
                  onPressed: () {
                    if (itemsJsonList.isEmpty) {
                      setState(() {
                        noItems = true;
                      });
                    }
                    if (locationsCloseToUserList.length >
                        numOfLocationsBeforeAdd) {
                      locationsCloseToUserList.removeWhere(
                          (e) => e == newLocationController.text.trim());
                    }
                    locationsJsonList.removeWhere(
                        (val) => val.name == newLocationController.text.trim());
                    getMarkers();
                    resetLocationList();
                    Navigator.pop(context);
                  },
                  child: const ButtonText('Cancel')),
            ),
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        processing = false;
                      });
                      if (formKey.currentState!.validate()) {
                        //New Item object
                        Item newItem = Item(
                          id: id,
                          name: safeString(nameController.text),
                          storeDate: timeNow.toLocal(),
                          location: locationNameValue,
                          multiple: multipleBool,
                          quantity: int.tryParse(
                                  safeString(quantityController.text)) ??
                              1,
                          description: safeString(descriptionController.text),
                        );
                        SQLResponse? sqlResponse =
                            await get(); //Get the latest data
                        if (sqlResponse?.status ==
                            SQLResponseStatusTypes.success) {
                          //Update the database and update [itemsJsonList]
                          SQLResponse? sqlPut = await newItem.put(
                              newLocation: (locationsCloseToUserList.length >
                                      numOfLocationsBeforeAdd &&
                                  locationsCloseToUserList.last ==
                                      locationNameValue),
                              newLocationColor: pickedColor,
                              newLocationCoordinates: currentLocationInstance);
                          setState(() {
                            processing = false;
                          });
                        } else {
                          setState(() {
                            processing = false;
                            networkError = true;
                          });
                        }
                        Navigator.pop(context);
                      }
                    },
                    child: const ButtonText("Update Item"))),
          ],
        ),
      ]),
    ));
  }
}
