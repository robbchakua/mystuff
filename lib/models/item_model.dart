import 'dart:convert';
import 'package:dad_app/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:dad_app/models/location_model.dart';
import 'package:dad_app/models/response_model.dart';
import 'package:dad_app/tests/php_test.dart';
import 'package:dad_app/utils/constants.dart';
import 'package:dad_app/utils/init.dart';
import 'package:dad_app/utils/utils.dart';
import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

List<Item> itemsFromJson(String str) =>
    List<Item>.from(json.decode(str).map((x) => Item.fromJson(x)));

String itemsToJson(List<Item> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Item {
  int? id;
  String? userid;
  String? name;
  DateTime? storeDate;
  String? location;
  String? image;
  bool? multiple;
  int? quantity; // If Multiple
  String? description;

  Item({
    this.id,
    this.userid,
    this.name,
    this.storeDate,
    this.location,
    this.image,
    this.multiple,
    this.quantity,
    this.description,
  });

  //Replace any characters that could affect the database.
  //
  // - "'" can make the query end
  //
  // - '"' can make the query end.
  //
  // - ',,,' used to separate the locations and items on get.
  String? get newName => safeString(name ?? 'null');

  String? get newLocationName => safeString(location ?? 'null');

  String? get newDescription => safeString(description ?? 'null');

  ///Get file name
  String get fileName => file.path.split('/').last;

  ///Converts to [Item]
  factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: int.parse(json["id"]),
        userid: json["userid"],
        name: json["name"],
        storeDate: DateTime.parse(json["storeDate"]),
        location: json["location"],
        image: json["image"],
        multiple: bool.parse(json["multiple"]),
        quantity: int.parse(json["quantity"]),
        description: json["description"],
      );

  ///Convert to json
  Map<String, dynamic> toJson() => {
        "id": id,
        "userid": User.user.userid,
        "name": name,
        "storeDate":
            "${storeDate?.year.toString().padLeft(4, '0')}-${storeDate?.month.toString().padLeft(2, '0')}-${storeDate?.day.toString().padLeft(2, '0')}",
        "locationName": location,
        "image": image,
        "multiple": multiple,
        "quantity": quantity,
        "description": description,
      };

  ///Converts to json to give the HTTP-request parameters.
  Future<FormData> toJsonExtended(
      {required RequestType requestType,
      required bool newLocation,
      Color? newLocationColor,
      String? oldImageLocation,
      LatLng? newLocationCoordinates}) async {
    //Return json
    return FormData.fromMap({
      "request": requestType.toString(), //0
      "id": id, //1
      "userid": User.user.userid, //2
      "name": newName, //3
      "storeDate":
          "${storeDate?.year.toString().padLeft(4, '0')}-${storeDate?.month.toString().padLeft(2, '0')}-${storeDate?.day.toString().padLeft(2, '0')}", //4
      "location": newLocationName, //5
      "multiple": multiple, //6
      "quantity": quantity, //7
      "description": newDescription, //8
      "newLocation": newLocation.toString(), //9
      "newLocationColor": colorToString(newLocationColor), //10
      "newLocationCoordinates": latLngToString(newLocationCoordinates), //11
      "oldImageLocation": oldImageLocation, //12
      "image": printInsteadOfPostBool
          ? 'image'
          : await MultipartFile.fromFile(file.path, filename: fileName),
    });
  }

  ///Converts to string

  @override
  String toString() => "Item[${getItemIndexFromId(id!)}]("
      "Id: ${id ?? 'null'}, "
      "UserId: ${User.user.userid ?? 'null'}, "
      "Name: ${name ?? 'null'}, "
      "Store Date: ${storeDate?.year.toString().padLeft(4, '0')}-"
      "${storeDate?.month.toString().padLeft(2, '0')}-"
      "${storeDate?.day.toString().padLeft(2, '0') ?? 'null'}, "
      "Location Name: ${location ?? 'null'}, "
      "Image: ${image ?? 'null'}, "
      "Multiple: ${multiple ?? 'null'}, "
      "Quantity: ${quantity ?? 'null'}, "
      "Description: ${description?.replaceAll('\n', '') ?? 'null'})";

  ///Posts new Item and adds to [itemsJsonList]
  Future<SQLResponse?> post(
      {required bool newLocation,
      Color? newLocationColor,
      LatLng? newLocationCoordinates}) async {
    try {
      //Convert to json
      var formData = await toJsonExtended(
          newLocation: newLocation,
          newLocationColor: newLocationColor,
          newLocationCoordinates: newLocationCoordinates,
          requestType: RequestType.postItem);

      //Print for debugging purposes instead of posting
      if (!printInsteadOfPostBool) {
        SQLResponse sqlResponse =
            SQLResponse(await Dio().post(Urls.postUrl, data: formData));
        if (sqlResponse.status == SQLResponseStatusTypes.success && !noUpdate) {
          itemsJsonList.add(Item(
              id: nextItemId(),
              userid: User.user.userid,
              name: newName,
              storeDate: timeNow,
              location: newLocationName,
              multiple: multiple,
              quantity: quantity,
              description: newDescription,
              image: "images/items/$fileName"));
          if (newLocation) {
            locationsJsonList.add(Location(
                id: nextLocationId(),
                userid: User.user.userid,
                name: newLocationName,
                location: latLngToString(newLocationCoordinates),
                color: colorToString(newLocationColor)));
          }
          resetItemList();
          resetLocationList();
          getMarkers();
        }
        return sqlResponse;
      } else {
        myPrint(toString());
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  ///Put Item and updates to [itemsJsonList]. Make sure to use the id for the item you want to update/put.
  ///Call [setState] after function
  Future<SQLResponse?> put(
      {required bool newLocation,
      Color? newLocationColor,
      LatLng? newLocationCoordinates,
      String? oldImageLocation}) async {
    try {
      //Convert data to json
      var formData = await toJsonExtended(
          newLocation: newLocation,
          oldImageLocation: oldImageLocation,
          newLocationColor: newLocationColor,
          newLocationCoordinates: newLocationCoordinates,
          requestType: RequestType.putItem);
      if (!printInsteadOfPostBool) {
        SQLResponse sqlResponse =
            SQLResponse(await Dio().post(Urls.postUrl, data: formData));
        if (sqlResponse.status == SQLResponseStatusTypes.success && !noUpdate) {
          for (var e in itemsJsonList) {
            if (e.id == id) {
              e.name = newName;
              e.image = "images/items/$image";
              e.location = newLocationName;
              e.multiple = multiple;
              e.quantity = quantity;
              e.description = newDescription;
            }
          }
          if (newLocation) {
            locationsJsonList.add(Location(
                id: nextLocationId(),
                userid: User.user.userid,
                name: newLocationName,
                location: latLngToString(newLocationCoordinates),
                color: colorToString(newLocationColor)));
          }
          resetItemList();
          resetLocationList();
          getMarkers();
        }

        return sqlResponse;
      } else {
        myPrint(toString());
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  ///Drops Item and deletes from [itemsJsonList]. The id is the only parameter needed while making/calling the item
  ///object. Call [setState] after function.
  Future<SQLResponse?> drop() async {
    try {
      var formData = FormData.fromMap({
        'request': RequestType.dropItem.toString(),
        'id': id,
        'userid': User.user.userid
      });
      if (!printInsteadOfPostBool) {
        SQLResponse sqlResponse =
            SQLResponse(await Dio().post(Urls.postUrl, data: formData));

        if (sqlResponse.status == SQLResponseStatusTypes.success && !noUpdate) {
          itemsJsonList.removeWhere((e) => e.id == id);
          resetItemList();
          resetLocationList();
          getMarkers();

          if (itemsJsonList.isEmpty) {
            noItems = true;
          } else {
            getMarkers();
            resetItemList();
          }
        }
        return sqlResponse;
      } else {
        myPrint("Deleted: ${formData.fields}");
        myPrint(toString());
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
