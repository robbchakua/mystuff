import 'package:dad_app/models/item_model.dart';
import 'package:dad_app/models/location_model.dart';
import 'package:dad_app/models/response_model.dart';
import 'package:dad_app/models/user_model.dart';
import 'package:dad_app/styles/themes.dart';
import 'package:dad_app/utils/init.dart';
import 'package:dad_app/utils/utils.dart';
import 'package:dad_app/widgets/text.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class PhpTest extends StatefulWidget {
  const PhpTest({super.key});

  @override
  State<PhpTest> createState() => _PhpTestState();
}

///Does not update [locationsJsonList] and [itemsJsonList}
bool noUpdate = false;

class _PhpTestState extends State<PhpTest> {
  Future<void> image() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? compressedImage = await imagePicker.pickImage(
        source: ImageSource.camera, imageQuality: 15);

    if (compressedImage != null) {
      setState(() {
        file = File(compressedImage.path);
      });
    }
  }

  @override
  void initState() {
    setState(() {
      noUpdate = true;
    });
    super.initState();
  }

  Item testItem = Item(
      id: 80,
      image: 'test',
      userid: 'userid',
      name: 'ahahahahah',
      quantity: 1,
      multiple: false,
      description: 'Test Item',
      location: 'testLocation',
      storeDate: timeNow);

  Location testLocation = Location(
      id: 46,
      userid: 'userid',
      name: 'setNewLocation',
      location: '21,41',
      color: '787C01');

  Location setNewTestLocation = Location(
      id: 0,
      userid: 'userid',
      name: 'setNewLocation',
      location: '21,21',
      color: 'C01757');

  User testUser = User(
      userid: 'userid',
      name: 'user',
      joinDate: DateTime(01, 01, 2000),
      password: 'password',
      email: 'user@gmail.com');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: screenHeight(context) - screenHeightWithSafeArea(context),
          ),
          Container(
            color: backgroundColor,
            height: screenHeightWithSafeArea(context),
            width: screenWidth(context),
            child: Column(
              children: [
                ElevatedButton(
                    onPressed: () async {
                      SQLResponse? response = await get();

                      List<Item>? items = response?.items;
                      // List<Location>? locations = response?.locations;

                      myPrint(response?.toString(extended: false));
                    },
                    child: const ButtonText('Get')),
                Row(
                  children: [
                    ElevatedButton(
                        onPressed: () async {
                          await image();
                          SQLResponse? response = await testItem.post(
                              newLocation: true,
                              newLocationCoordinates:
                                  stringToLatLng(testLocation.location!),
                              newLocationColor:
                                  stringToColor(testLocation.color!));

                          myPrint(response);
                        },
                        child: const ButtonText('Post Item')),
                    ElevatedButton(
                        onPressed: () async {
                          await image();
                          SQLResponse? response = await testItem.put(
                              newLocation: true,
                              newLocationCoordinates:
                                  stringToLatLng(testLocation.location!),
                              newLocationColor:
                                  stringToColor(testLocation.color!));

                          myPrint(response);
                        },
                        child: const ButtonText('Put Item')),
                    ElevatedButton(
                        onPressed: () async {
                          SQLResponse? response = await testItem.drop();

                          myPrint(response?.toString());
                        },
                        child: const ButtonText('Drop Item'))
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton(
                        onPressed: () async {
                          SQLResponse? response =
                              await testLocation.put('testLocation');

                          myPrint(response);
                        },
                        child: const ButtonText('Put Location')),
                    ElevatedButton(
                        onPressed: () async {
                          SQLResponse? response =
                              await testLocation.drop(allItems: true);

                          myPrint(response);
                        },
                        child: const ButtonText('Drop w/ items')),
                    ElevatedButton(
                        onPressed: () async {
                          //Made some changes and the test for this may not work.
                          //drop works well on application...

                          SQLResponse? response = await testLocation.drop(
                              allItems: false,
                              oldName: setNewTestLocation.name);

                          myPrint(response);
                        },
                        child: const ButtonText('Drop w/ set'))
                  ],
                ),
                SizedBox(height: screenHeight(context) / 10),
                Row(
                  children: [
                    ElevatedButton(
                        onPressed: () async {
                          SQLResponse? response = await testUser.post(false);

                          myPrint(response);
                        },
                        child: const ButtonText('Post User')),
                    ElevatedButton(
                        onPressed: () async {
                          SQLResponse? response = await testUser.get();

                          myPrint(response);
                        },
                        child: const ButtonText('Get User')),
                    ElevatedButton(
                        onPressed: () async {
                          SQLResponse? response = await testUser.drop();

                          myPrint(response);
                        },
                        child: const ButtonText('Drop User')),
                  ],
                ),
                ElevatedButton(
                    onPressed: () async {
                      List? response = await testUser.verifyEmail();
                      myPrint(response);
                    },
                    child: const ButtonText('Verify Email')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
