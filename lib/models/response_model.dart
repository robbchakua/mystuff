import 'package:dad_app/models/user_model.dart';
import 'package:dad_app/tests/php_test.dart';
import 'package:dad_app/utils/init.dart';
import 'package:dio/dio.dart';
import '../utils/constants.dart';
import '../utils/utils.dart';
import 'location_model.dart';
import 'item_model.dart';

///Get item and location data
Future<SQLResponse?> get() async {
  var formData = FormData.fromMap({
    'request': RequestType.get.toString(),
    'id': 0,
    'userid': noUpdate ? 'userid' : User.user.userid,
    //Get items and locations with 'userid' as the userid in
    //noUpdateMode/php debug mode
  });

  if (!printInsteadOfPostBool) {
    SQLResponse sqlResponse =
        SQLResponse(await Dio().post(Urls.postUrl, data: formData));

    if (sqlResponse.status == SQLResponseStatusTypes.success) {
      itemsJsonList = sqlResponse.items!;
      locationsJsonList = sqlResponse.locations!;
    }

    return sqlResponse;
  } else {
    myPrint('Get: ${formData.fields}');
    return null;
  }
}

class SQLResponse {
  Response response;

  SQLResponse(this.response);

  ///Returns the status of the the request
  SQLResponseStatusTypes get status {
    /// If the HTTP request responds unsuccessfully
    if (data[0] == "SQLResponseStatusTypes.sql") {
      // SQL error message
      return SQLResponseStatusTypes.sql;
    }

    // If the HTTP request responds successfully
    else if (data[0] == "SQLResponseStatusTypes.success") {
      return SQLResponseStatusTypes.success;
    }

    //If none of the IF statements in the request can validate the requestType

    else if (data[0] == "SQLResponseStatusTypes.codeError") {
      return SQLResponseStatusTypes.codeError;
    }

    // If the HTTP request responds null
    else {
      // Unknown Response
      return SQLResponseStatusTypes.unknown;
    }
  }

  ///Get user from Response
  User? get user {
    if (status != SQLResponseStatusTypes.unknown) {
      if (data[3] != '[]') {
        return userFromJson(data[3])[0];
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  ///Get Items from Response
  List<Item>? get items {
    if (status != SQLResponseStatusTypes.unknown) {
      return itemsFromJson(data[4]);
    } else {
      return null;
    }
  }

  ///Get Location from Response
  List<Location>? get locations {
    if (status != SQLResponseStatusTypes.unknown) {
      return locationsFromJson(data[5]);
    } else {
      return null;
    }
  }

  String get errorMessage {
    if (status != SQLResponseStatusTypes.unknown) {
      return data[1];
    } else {
      // If the response data has an error/warning. It will get the error/warning
      //If there is a warning, the code may continue on so to avoid this I split the string
      //and get the first entry which will be the error/warning
      return (response.data as String).split('SQLResponseStatusTypes')[0];
    }
  }

  String get successMessage {
    if (status != SQLResponseStatusTypes.unknown) {
      return data[2];
    } else {
      return 'null';
    }
  }

  /// Splits the data into a List.
  ///
  /// [
  ///
  /// responseType - 0
  ///
  /// SQL error message | Unknown Errors | CodeErrors - 1
  ///
  /// SQL success message - 2
  ///
  /// user - 3
  ///
  /// items - 4
  ///
  /// locations - 5
  ///
  /// ]
  ///
  ///
  ///EXAMPLE 1: SQL Error
  ///
  /// [
  ///
  /// [SQLResponseStatusTypes.sql] - 0,
  ///
  /// "Maria DB Exception on line 1 'location = supermarket'." - 1,
  ///
  /// "null" - It did not succeed. Leaving it like "null" will avoid RangeErrors - 2,
  ///
  /// "null" - 3 ^^ no user
  ///
  /// "null" - 4  ^^ no items
  ///
  /// "null" - 5 ^^ no locations
  ///
  /// ]
  List get data => response.data.split(',,,');

  @override
  String toString({bool? extended}) {
    String returnItems = 'null';
    String returnLocation = 'null';
    bool userNull = false;
    if (status != SQLResponseStatusTypes.unknown ||
        status != SQLResponseStatusTypes.sql) {
      if (data[3] == 'null') {
        userNull = true;
      }
      if (data[4] != 'null') {
        if (extended!) {
          returnItems = itemsToJson(items!);
        } else {
          returnItems = "${items?.length} records";
        }
      }
      if (data[5] != 'null') {
        if (extended!) {
          returnLocation = locationsToJson(locations!);
        } else {
          returnLocation = "${locations?.length} records";
        }
      }
    }
    return "Response Type: ${status == SQLResponseStatusTypes.unknown ? SQLResponseStatusTypes.unknown : data[0]}, "
        "SQL Error Message: $errorMessage, "
        "SQL Success Message: $successMessage, "
        "User: ${userNull ? "null" : user?.toJson()}, "
        "Items: $returnItems, Locations: $returnLocation";
  }
}

enum SQLResponseStatusTypes { codeError, success, sql, unknown }
