import 'dart:convert';
import 'dart:io';

import 'package:dad_app/models/response_model.dart';
import 'package:dad_app/models/user_model.dart';
import 'package:dad_app/utils/constants.dart';
import 'package:dad_app/utils/api.dart';
import 'package:dad_app/utils/init.dart';
import 'package:dad_app/utils/utils.dart';
import 'package:dio/dio.dart';

List<Location> locationsFromJson(String str) => List<Location>.from(
    (json.decode(str) as List).map((value) => Location.fromJson(value)));

String locationsToJson(List<Location> data) =>
    json.encode(data.map((bin) => bin.toJson()).toList());

/// A physical storage bin. The historical class name is retained to avoid a
/// visual/UI overhaul while the application moves from locations to bins.
class Location {
  int? id;
  String? userid;
  int? parentId;
  String? name;
  String? description;
  String? location;
  String? color;
  String? image;
  String? permission;
  bool canEdit;
  bool canManageAccess;

  Location({
    this.id,
    this.userid,
    this.parentId,
    this.name,
    this.description,
    this.location,
    this.color,
    this.image,
    this.permission,
    this.canEdit = false,
    this.canManageAccess = false,
  });

  String get newName => safeString(name ?? '');

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        id: _asInt(json['id']),
        userid: json['userid']?.toString(),
        parentId: _asInt(json['parentId'] ?? json['parent_id']),
        name: json['name']?.toString(),
        description: json['description']?.toString() ?? '',
        location: json['location']?.toString() ?? '',
        color: json['color']?.toString() ?? 'F44336',
        image: json['image']?.toString(),
        permission: json['permission']?.toString() ?? 'view',
        canEdit: _asBool(json['canEdit']),
        canManageAccess: _asBool(json['canManageAccess']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userid': userid,
        'parentId': parentId,
        'name': name,
        'description': description,
        'location': location,
        'color': color,
        'image': image,
        'permission': permission,
        'canEdit': canEdit,
        'canManageAccess': canManageAccess,
      };

  Future<SQLResponse?> post({File? imageFile}) async {
    try {
      final formData = FormData.fromMap({
        'request': RequestType.postBin.toString(),
        'token': User.user.sessionToken,
        'parentId': parentId,
        'name': newName,
        'description': description ?? '',
        'location': location ?? '',
        'color': color ?? 'F44336',
        if (imageFile != null && imageFile.path.isNotEmpty)
          'image': await MultipartFile.fromFile(imageFile.path),
      });
      if (printInsteadOfPostBool) {
        myPrint('Create bin: ${formData.fields}');
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

  /// Updates this bin. [oldName] remains optional for calls made by the old UI.
  Future<SQLResponse?> put([String? oldName, File? imageFile]) async {
    try {
      final formData = FormData.fromMap({
        'request': RequestType.putBin.toString(),
        'token': User.user.sessionToken,
        'binId': id,
        'parentId': parentId,
        'name': newName,
        'description': description ?? '',
        'location': location ?? '',
        'color': color ?? 'F44336',
        if (imageFile != null && imageFile.path.isNotEmpty)
          'image': await MultipartFile.fromFile(imageFile.path),
      });
      if (printInsteadOfPostBool) {
        myPrint('Update bin: ${formData.fields}');
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

  /// Deletes the bin and either its full branch or moves its direct contents
  /// to the bin identified by [replacementBinId].
  Future<SQLResponse?> drop({
    required bool allItems,
    String? oldName,
    int? replacementBinId,
  }) async {
    try {
      replacementBinId ??= allItems ? null : getLocationIdFromName(name ?? '');
      final formData = FormData.fromMap({
        'request': RequestType.dropBin.toString(),
        'token': User.user.sessionToken,
        'binId': id,
        'deleteContents': allItems,
        'replacementBinId': replacementBinId,
      });
      if (printInsteadOfPostBool) {
        myPrint('Delete bin: ${formData.fields}');
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

  Future<SQLResponse?> getAccess() async {
    try {
      return SQLResponse(await apiClient.post(
        Urls.postUrl,
        data: FormData.fromMap({
          'request': RequestType.getBinAccess.toString(),
          'token': User.user.sessionToken,
          'binId': id,
        }),
      ));
    } catch (error) {
      myPrint(error);
      return null;
    }
  }

  Future<SQLResponse?> grantAccess(int userId, String access) async {
    try {
      return SQLResponse(await apiClient.post(
        Urls.postUrl,
        data: FormData.fromMap({
          'request': RequestType.grantBinAccess.toString(),
          'token': User.user.sessionToken,
          'binId': id,
          'userId': userId,
          'permission': access,
        }),
      ));
    } catch (error) {
      myPrint(error);
      return null;
    }
  }

  Future<SQLResponse?> revokeAccess(int userId) async {
    try {
      return SQLResponse(await apiClient.post(
        Urls.postUrl,
        data: FormData.fromMap({
          'request': RequestType.revokeBinAccess.toString(),
          'token': User.user.sessionToken,
          'binId': id,
          'userId': userId,
        }),
      ));
    } catch (error) {
      myPrint(error);
      return null;
    }
  }

  static void _applyData(SQLResponse response) {
    if (response.status != SQLResponseStatusTypes.success) return;
    itemsJsonList = response.items;
    locationsJsonList = response.locations;
    resetItemList();
    resetLocationList();
    getMarkers();
  }
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
