import 'dart:convert';

import 'package:dad_app/models/response_model.dart';
import 'package:dad_app/models/user_model.dart';
import 'package:dad_app/utils/constants.dart';
import 'package:dad_app/utils/api.dart';
import 'package:dad_app/utils/init.dart';
import 'package:dad_app/utils/item_tags.dart';
import 'package:dad_app/utils/utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

List<Item> itemsFromJson(String str) => List<Item>.from(
    (json.decode(str) as List).map((value) => Item.fromJson(value)));

String itemsToJson(List<Item> data) =>
    json.encode(data.map((item) => item.toJson()).toList());

class Item {
  int? id;
  String? userid;
  String? name;
  DateTime? storeDate;
  int? binId;
  String? location;
  String? image;
  bool? multiple;
  int? quantity;
  String? description;
  List<String> tags;
  bool canEdit;

  Item({
    this.id,
    this.userid,
    this.name,
    this.storeDate,
    this.binId,
    this.location,
    this.image,
    this.multiple,
    this.quantity,
    this.description,
    this.tags = const [],
    this.canEdit = false,
  });

  String get newName => safeString(name ?? '');
  String get newDescription => safeString(description ?? '');
  String get fileName => file.path.split('/').last;

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: _asInt(json['id']),
        userid: json['userid']?.toString(),
        name: json['name']?.toString(),
        storeDate: DateTime.tryParse(json['storeDate']?.toString() ?? ''),
        binId: _asInt(json['binId'] ?? json['bin_id']),
        location: json['location']?.toString(),
        image: json['image']?.toString(),
        multiple: _asBool(json['multiple']),
        quantity: _asInt(json['quantity']) ?? 1,
        description: json['description']?.toString() ?? '',
        tags: decodeItemTags(json['tags']),
        canEdit: _asBool(json['canEdit']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userid': userid,
        'name': name,
        'storeDate': _dateString(storeDate),
        'binId': binId,
        'location': location,
        'image': image,
        'multiple': multiple,
        'quantity': quantity,
        'description': description,
        'tags': tags,
        'canEdit': canEdit,
      };

  Future<FormData> toJsonExtended({required RequestType requestType}) async {
    final resolvedBinId = binId ?? getLocationIdFromName(location ?? '');
    return FormData.fromMap({
      'request': requestType.toString(),
      'token': User.user.sessionToken,
      'id': id,
      'name': newName,
      'storeDate': _dateString(storeDate ?? timeNow),
      'binId': resolvedBinId == 0 ? null : resolvedBinId,
      'multiple': multiple ?? false,
      'quantity': quantity ?? 1,
      'description': newDescription,
      'tags': encodeItemTags(tags),
      if (file.path.isNotEmpty)
        'image': await MultipartFile.fromFile(file.path, filename: fileName),
    });
  }

  @override
  String toString() => 'Item(Id: $id, Name: $name, BinId: $binId, '
      'Bin: $location, Image: $image, Multiple: $multiple, '
      'Quantity: $quantity, Description: $description, Tags: $tags)';

  Future<SQLResponse?> post({
    bool newLocation = false,
    Color? newLocationColor,
    LatLng? newLocationCoordinates,
  }) async {
    try {
      final formData = await toJsonExtended(requestType: RequestType.postItem);
      if (printInsteadOfPostBool) {
        myPrint(toString());
        return null;
      }
      final response =
          SQLResponse(await apiClient.post(Urls.postUrl, data: formData));
      _applyData(response);
      return response;
    } catch (error) {
      myPrint(error);
      return null;
    }
  }

  Future<SQLResponse?> put({
    bool newLocation = false,
    Color? newLocationColor,
    LatLng? newLocationCoordinates,
    String? oldImageLocation,
  }) async {
    try {
      final formData = await toJsonExtended(requestType: RequestType.putItem);
      if (printInsteadOfPostBool) {
        myPrint(toString());
        return null;
      }
      final response =
          SQLResponse(await apiClient.post(Urls.postUrl, data: formData));
      _applyData(response);
      return response;
    } catch (error) {
      myPrint(error);
      return null;
    }
  }

  Future<SQLResponse?> drop() async {
    try {
      final formData = FormData.fromMap({
        'request': RequestType.dropItem.toString(),
        'token': User.user.sessionToken,
        'id': id,
      });
      if (printInsteadOfPostBool) {
        myPrint('Delete item $id');
        return null;
      }
      final response =
          SQLResponse(await apiClient.post(Urls.postUrl, data: formData));
      _applyData(response);
      return response;
    } catch (error) {
      myPrint(error);
      return null;
    }
  }

  static void _applyData(SQLResponse response) {
    if (response.status != SQLResponseStatusTypes.success) return;
    itemsJsonList = response.items;
    locationsJsonList = response.locations;
    noItems = itemsJsonList.isEmpty;
    resetItemList();
    resetLocationList();
    getMarkers();
  }
}

String _dateString(DateTime? date) {
  final value = date ?? DateTime.now();
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

int? _asInt(dynamic value) {
  if (value == null || value.toString().isEmpty) return null;
  return int.tryParse(value.toString());
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return value?.toString().toLowerCase() == 'true' || value?.toString() == '1';
}
