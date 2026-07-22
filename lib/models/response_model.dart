import 'dart:convert';

import 'package:dad_app/models/item_model.dart';
import 'package:dad_app/models/location_model.dart';
import 'package:dad_app/models/user_model.dart';
import 'package:dad_app/utils/constants.dart';
import 'package:dad_app/utils/api.dart';
import 'package:dad_app/utils/init.dart';
import 'package:dad_app/utils/utils.dart';
import 'package:dio/dio.dart';

/// Loads the items and bins the current server-authenticated user can access.
Future<SQLResponse?> get() async {
  try {
    final formData = FormData.fromMap({
      'request': RequestType.get.toString(),
      'token': User.user.sessionToken,
    });
    if (printInsteadOfPostBool) {
      myPrint('Get data requested');
      return null;
    }

    final sqlResponse =
        SQLResponse(await apiClient.post(Urls.postUrl, data: formData));
    if (sqlResponse.status == SQLResponseStatusTypes.success) {
      itemsJsonList = sqlResponse.items;
      locationsJsonList = sqlResponse.locations;
      resetItemList();
      resetLocationList();
    }
    return sqlResponse;
  } catch (error) {
    myPrint(error);
    return null;
  }
}

class SQLResponse {
  final Response response;
  late final Map<String, dynamic> payload = _decodePayload(response.data);

  SQLResponse(this.response);

  SQLResponseStatusTypes get status {
    switch (payload['status']?.toString()) {
      case 'success':
        return SQLResponseStatusTypes.success;
      case 'unauthorized':
        return SQLResponseStatusTypes.unauthorized;
      case 'forbidden':
        return SQLResponseStatusTypes.forbidden;
      case 'invalid':
        return SQLResponseStatusTypes.codeError;
      case 'conflict':
        return SQLResponseStatusTypes.conflict;
      case 'notFound':
        return SQLResponseStatusTypes.notFound;
      case 'error':
        return SQLResponseStatusTypes.sql;
      default:
        return SQLResponseStatusTypes.unknown;
    }
  }

  User? get user {
    final value = payload['user'];
    return value is Map
        ? User.fromJson(Map<String, dynamic>.from(value))
        : null;
  }

  List<User> get users => _mapList(payload['users'], User.fromJson);

  List<Item> get items => _mapList(payload['items'], Item.fromJson);

  List<Location> get locations {
    final value = payload['bins'] ?? payload['locations'];
    return _mapList(value, Location.fromJson);
  }

  List<Map<String, dynamic>> get permissions {
    final value = payload['permissions'];
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  }

  int? get binId => int.tryParse(payload['binId']?.toString() ?? '');

  bool get emailExists =>
      payload['emailExists'] == true ||
      payload['emailExists']?.toString() == '1';

  String get errorMessage => payload['message']?.toString() ?? 'Unknown error';

  String get successMessage => payload['message']?.toString() ?? '';

  @override
  String toString({bool extended = false}) {
    final itemText = extended ? itemsToJson(items) : '${items.length} records';
    final binText =
        extended ? locationsToJson(locations) : '${locations.length} records';
    return 'Response Type: $status, Message: ${payload['message']}, '
        'User: ${user?.toJson()}, Items: $itemText, Bins: $binText';
  }
}

enum SQLResponseStatusTypes {
  codeError,
  success,
  sql,
  unauthorized,
  forbidden,
  conflict,
  notFound,
  unknown,
}

Map<String, dynamic> _decodePayload(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  if (data is String) {
    final decoded = json.decode(data);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  }
  return {'status': 'unknown', 'message': 'Invalid server response'};
}

List<T> _mapList<T>(dynamic value, T Function(Map<String, dynamic>) parser) {
  if (value is! List) return [];
  return value
      .whereType<Map>()
      .map((entry) => parser(Map<String, dynamic>.from(entry)))
      .toList();
}
