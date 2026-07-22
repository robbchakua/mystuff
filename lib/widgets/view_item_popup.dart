import 'package:cached_network_image/cached_network_image.dart';
import 'package:dad_app/utils/utils.dart';
import 'package:dad_app/widgets/text.dart';
import 'package:dad_app/widgets/update_item_popup_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/item_model.dart';
import '../models/response_model.dart';
import '../pages/location_page.dart';
import '../utils/constants.dart';
import '../utils/init.dart';
import '../styles/themes.dart';
import 'dart:io';

class ViewItemColumn extends StatefulWidget {
  final int id;
  final int locationId;
  final String? name;
  final String? location;
  final bool? multiple;
  final int? quantity;
  final String? description;

  ViewItemColumn(
      {super.key,
      required this.id,
      required this.locationId,
      this.name,
      this.location,
      this.multiple,
      this.quantity,
      this.description});

  @override
  State<ViewItemColumn> createState() => ViewItemColumnState(
        id: id,
        name: name,
        location: location,
        multiple: multiple,
        quantity: quantity,
        description: description,
        locationId: locationId,
      );
}

class ViewItemColumnState extends State<ViewItemColumn> {
  late int id;
  int locationId;
  late String? name;
  late String? location;
  late bool? multiple;
  late int? quantity;
  late String? description;

  ViewItemColumnState(
      {required this.id,
      required this.locationId,
      this.name,
      this.location,
      this.multiple,
      this.quantity,
      this.description});

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final quantityController = TextEditingController();
  final formKey = GlobalKey<FormState>(debugLabel: 'viewForm');

  bool multipleBool = false;
  bool setImage = false;

  @override
  void initState() {
    setState(() {
      if (multiple!) {
        multipleBool = true;
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

  bool deletedItem = false;

  Future updateItemPage() => showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
            content: UpdateItemColumn(
                id: id,
                name: name,
                location: location,
                description: description,
                multiple: multiple,
                quantity: quantity),
            backgroundColor: primaryColor(context),
          ));

  void updateItem() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? compressedImage = await imagePicker.pickImage(
        source: ImageSource.camera, imageQuality: 15);

    if (compressedImage != null) {
      setState(() {
        file = File(compressedImage.path);
      });

      await updateItemPage();
      Navigator.pop(context);
    }
  }

  Future deleteItem({required int id, required String title}) => showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: Text('Delete: \n$title?'),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    onPressed: () async {
                      SQLResponse? sqlDrop = await Item(id: id).drop();
                      setState(() {});
                      if (sqlDrop?.status == SQLResponseStatusTypes.success) {
                        setState(() {
                          deletedItem = true;
                        });
                      }
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Yes',
                      style: TextStyle(color: inverseColor(context)),
                    )),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'No',
                      style: TextStyle(color: inverseColor(context)),
                    )),
              ],
            ),
          ));

  @override
  Widget build(BuildContext context) {
    final currentItem = getItemIndexFromId(id) >= 0
        ? itemsJsonList[getItemIndexFromId(id)]
        : null;
    final canEdit = currentItem?.canEdit ?? false;
    final bin = getLocationFromId(locationId);
    return SizedBox(
        width: screenWidth(context) / 4,
        child: SingleChildScrollView(
            child: Form(
          key: formKey,
          child: Column(children: [
            Padding(
                padding: EdgeInsets.all(screenWidth(context) / 50),
                child: Header(name!)),
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      color: secondaryColor(context),
                      border: Border.all(color: inverseColor(context))),
                  width: screenWidth(context) / 1.4,
                  height: screenWidth(context) / 1.4,
                  child: CachedNetworkImage(
                    fit: BoxFit.cover,
                    imageUrl:
                        "${Urls.baseUrl}/${itemsJsonList[getItemIndexFromId(id)].image}",
                    progressIndicatorBuilder:
                        (context, url, downloadProgress) => Center(
                      child: CircularProgressIndicator(
                          value: downloadProgress.progress),
                    ),
                    errorWidget: (context, url, error) {
                      myPrint(error);
                      return Image.file(
                        file,
                        fit: BoxFit.contain,
                        height: screenHeight(context) / 20,
                        errorBuilder: (context, error, stackTrace) {
                          myPrint(error);
                          return const Icon(Icons.image_not_supported);
                        },
                      );
                    },
                  ),
                )),
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: SubHeader(
                            'Bin: ${bin == null ? location : binDisplayPath(bin)}')),
                    CircleAvatar(
                      backgroundColor: const Color(0xAA1B1B1B),
                      foregroundColor: inverseColor(context),
                      radius: screenWidth(context) / 17,
                      child: IconButton(
                          onPressed: bin?.location?.contains(',') == true
                              ? () async {
                                  if (!networkError) {
                                    setState(() {
                                      listItems = false;
                                      listLocations = false;
                                      targetPosition = stringToLatLng(
                                          locationsJsonList[
                                                  getLocationIndexFromId(
                                                      locationId)]
                                              .location!);
                                    });
                                    if (googleMapsController.isCompleted) {
                                      GoogleMapController controller =
                                          await googleMapsController.future;
                                      controller.animateCamera(CameraUpdate
                                          .newCameraPosition(CameraPosition(
                                              target: stringToLatLng(
                                                  locationsJsonList[
                                                          getLocationIndexFromId(
                                                              locationId)]
                                                      .location!),
                                              zoom: cameraZoom >= 17
                                                  ? cameraZoom
                                                  : 17)));
                                    }
                                    Get.to(() => ItemLocationScreen(
                                          withTarget: true,
                                        ));
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content:
                                                BodyText('Network Error...')));
                                  }
                                }
                              : null,
                          icon: const Icon(Icons.location_on)),
                    )
                  ],
                )),
            Divider(color: inverseColor(context)),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: BodyText(
                  'Saved on ${DateFormat.yMMMMd().format(itemsJsonList[getItemIndexFromId(id)].storeDate!)}'),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: BodyText('Number of item(s): $quantity'),
            ),
            if (canEdit)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: updateItem,
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(const Color(0xAA1B1B1B))),
                    child: const ButtonText('Update Item'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await deleteItem(id: id, title: name!);
                      if (deletedItem && context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(const Color(0xAAFF0000))),
                    child: const ButtonText('Delete Item'),
                  )
                ],
              )
          ]),
        )));
  }
}
