import 'dart:convert';

import 'package:dad_app/models/response_model.dart';
import 'package:dad_app/models/user_model.dart';
import 'package:dad_app/utils/constants.dart';
import 'package:dad_app/utils/init.dart';
import 'package:dio/dio.dart';

import '../utils/utils.dart';

List<Location> locationsFromJson(String str) =>
    List<Location>.from(json.decode(str).map((x) => Location.fromJson(x)));

String locationsToJson(List<Location> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Location {
  int? id;
  String? userid;
  String? name;
  String? location;
  String? color;

  Location({
    this.id,
    this.userid,
    this.name,
    this.location,
    this.color,
  });

  String get newName => safeString(name!);

  factory Location.fromJson(Map<String, dynamic> json) => Location(
      id: int.parse(json["id"]),
      userid: json["userid"],
      name: json["name"],
      location: json["location"],
      color: json["color"]);

  Map<String, dynamic> toJson() => {
        "id": id,
        "userid": User.user.userid,
        "name": name,
        "location": location,
        "color": color,
      };

  ///Make sure to use the id for the location you want to update/put.
  ///location parameter can be ' '.
  ///The name of the location object should be the new name. Call [setState]
  ///after function
  Future<SQLResponse?> put(String oldName) async {
    try {
      var formData = FormData.fromMap({
        'request': RequestType.putLocation.toString(), //0
        'id': id, //1
        'userid': User.user.userid, //2
        'name': newName, //3
        'oldName': oldName, //4
        'location': location, //5
        'color': color, //6
      });

      if (!printInsteadOfPostBool) {
        SQLResponse sqlResponse =
            SQLResponse(await Dio().post(Urls.postUrl, data: formData));

        if (sqlResponse.status == SQLResponseStatusTypes.success) {
          for (var e in itemsJsonList) {
            if (e.location == oldName) {
              e.location = newName;
            }
          }

          for (var e in locationsJsonList) {
            if (e.name == oldName) {
              e.name = newName;
              e.color = color;
            }
          }
          getMarkers();
          resetItemList();
          resetLocationList();
        }
        return sqlResponse;
      } else {
        myPrint('Editing: ${formData.fields}');
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  ///Either drops and sets items to new location or drops along with items.
  ///Make sure the location object's name and id are the filled.
  ///Call [setState] after function.
  Future<SQLResponse?> drop({required bool allItems, String? oldName}) async {
    try {
      var formData = FormData.fromMap({
        'request': allItems
            ? RequestType.dropLocationWithAll.toString()
            : RequestType.dropLocationSetNew.toString(), //0
        'id': id, //1
        'userid': User.user.userid, //2
        'name': allItems ? name : safeString(name!),
        'oldName': allItems ? "" : oldName, //4
        'location': location, //5
        'color': color, //6
      });

      if (!printInsteadOfPostBool) {
        SQLResponse sqlResponse =
            SQLResponse(await Dio().post(Urls.postUrl, data: formData));

        if (sqlResponse.status == SQLResponseStatusTypes.success) {
          if (allItems) {
            locationsJsonList.removeWhere((e) => e.id == id);
            itemsJsonList.removeWhere((e) => e.location == oldName);
            resetItemList();
            resetLocationList();
            getMarkers();
          } else {
            locationsJsonList.removeWhere((e) => e.id == id);
            for (var e in itemsJsonList) {
              if (e.location == oldName) {
                e.location = newName;
              }
            }
            locationsJsonList.add(Location(
                id: nextLocationId(),
                userid: User.user.userid,
                name: newName,
                color: color,
                location: location));
            resetItemList();
            resetLocationList();
            getMarkers();
          }
        }

        return sqlResponse;
      } else {
        myPrint('Deleted: ${formData.fields}');
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
