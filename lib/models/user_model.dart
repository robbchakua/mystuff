import 'dart:convert';
import 'dart:math';

import 'package:dad_app/models/response_model.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:location/location.dart';

import '../pages/sign_up_or_log_in_page.dart';
import '../utils/constants.dart';
import '../utils/init.dart';
import '../utils/utils.dart';

List<User> userFromJson(String str) =>
    List<User>.from(json.decode(str).map((x) => User.fromJson(x)));

String userToJson(List<User> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class User {
  String? userid;
  String? name;
  String? email;
  String? password;
  DateTime? joinDate;

  User({
    this.userid,
    this.name,
    this.email,
    this.password,
    this.joinDate,
  });

  static User user = User();

  factory User.fromJson(Map<String, dynamic> json) => User(
        userid: json["userid"],
        name: json["name"],
        email: json["email"],
        // Passwords are never expected in server responses or local sessions.
        password: null,
        joinDate: DateTime.parse(json["joinDate"]),
      );

  Map<String, dynamic> toJson() => {
        "userid": userid,
        "name": name,
        "email": email,
        "joinDate":
            "${joinDate?.year.toString().padLeft(4, '0')}-${joinDate?.month.toString().padLeft(2, '0')}-${joinDate?.day.toString().padLeft(2, '0')}",
      };

  @override
  String toString() =>
      "User(UserId: $userid, Name: $name, Email: $email, Password: [redacted], "
      "JoinDate: ${joinDate?.year.toString().padLeft(4, '0')}-${joinDate?.month.toString().padLeft(2, '0')}-${joinDate?.day.toString().padLeft(2, '0')})";

  ///Posts new user. If user is gAccount, no parameters are needed. As long as
  ///The [getGoogleAccount] was called prior to the function.
  ///Call [setState] after function
  Future<SQLResponse?> post(bool isGAccount) async {
    //Check if there is internet connection
    try {
      String gAccountUserid =
          "${google.currentUser?.displayName?.toLowerCase().removeAllWhitespace}${Random().nextInt(1000)}";
      //Creates new user json
      var formData = FormData.fromMap({
        'request': RequestType.postUser.toString(),
        'userid': isGAccount ? gAccountUserid : userid,
        'name': isGAccount ? google.currentUser?.displayName : name,
        'email': isGAccount ? google.currentUser?.email : email,
        'password': isGAccount ? gAccount : password,
        'joinDate': timeNow,
      });

      if (!printInsteadOfPostBool) {
        //Posts to db
        SQLResponse sqlResponse =
            SQLResponse(await Dio().post(Urls.userUrl, data: formData));

        if (sqlResponse.status == SQLResponseStatusTypes.success) {
          if (isGAccount) {
            //If it is a GAccount, create the userid and get the location Permissions
            user = User(
                userid: gAccountUserid,
                name: google.currentUser?.displayName,
                email: google.currentUser?.email,
                password: gAccount,
                joinDate: timeNow);
            preferences.setString('user', userToJson([user]));
            PermissionStatus permissionGranted;
            permissionGranted = await gvLocation.hasPermission();
            if (permissionGranted == PermissionStatus.denied) {
              permissionGranted = await gvLocation.requestPermission();
              if (permissionGranted != PermissionStatus.granted) {}
            } else if (permissionGranted == PermissionStatus.granted) {
              LocationData locationData = await gvLocation.getLocation();
              userLocation =
                  LatLng(locationData.latitude!, locationData.longitude!);
            }
          } else {
            user = User(
                userid: userid,
                name: name,
                email: 'NO-EMAIL',
                password: password,
                joinDate: timeNow);

            preferences.setString('user', userToJson([user]));
            PermissionStatus permissionGranted;
            permissionGranted = await gvLocation.hasPermission();
            if (permissionGranted == PermissionStatus.denied) {
              permissionGranted = await gvLocation.requestPermission();
              if (permissionGranted != PermissionStatus.granted) {}
            } else if (permissionGranted == PermissionStatus.granted) {
              LocationData locationData = await gvLocation.getLocation();
              userLocation =
                  LatLng(locationData.latitude!, locationData.longitude!);
            }
          }
        }
        return sqlResponse;
      } else {
        myPrint('Post: ${formData.fields}');
        return null;
      }
    } catch (e) {
      myPrint(e);
      return null;
    }
  }

  @Deprecated('Not fully implemented.')

  ///Updates the user. Call [setState] after function
  Future<SQLResponse?> put() async {
    var formData = FormData.fromMap({
      'request': RequestType.putUser.toString(),
      'userid': userid,
      'name': name,
      'email': email,
      'password': password,
      'joinDate': ''
    });

    SQLResponse? sqlResponse =
        SQLResponse(await Dio().post(Urls.userUrl, data: formData));

    if (!printInsteadOfPostBool) {
      if (sqlResponse.status == SQLResponseStatusTypes.success) {
        User.user.email = email;
        hasEmailBool = true;
      }
      return sqlResponse;
    } else {
      myPrint('Edit: ${formData.fields}');
      return null;
    }
  }

  ///Authenticates the user on the server. Password verification must never be
  ///performed by the Flutter client.
  Future<SQLResponse?> get() async {
    try {
      //Json to be sent to php
      var formData = FormData.fromMap({
        'request': RequestType.login.toString(),
        'userid': userid,
        'name': '',
        'email': email,
        'password': password,
        'joinDate': '',
      });

      if (!printInsteadOfPostBool) {
        SQLResponse sqlResponse =
            SQLResponse(await Dio().post(Urls.userUrl, data: formData));
        return sqlResponse; // Returned to be validated
      } else {
        myPrint('Get: ${formData.fields}');
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  ///Drop the user along with their locations and items
  Future<SQLResponse?> drop({String? currentPassword}) async {
    try {
      //Json sent to php
      var formData = FormData.fromMap({
        'request': RequestType.dropUser.toString(),
        'userid': userid,
        'name': '',
        'email': '',
        'password': currentPassword,
        'joinDate': '',
      });
      if (!printInsteadOfPostBool) {
        SQLResponse sqlResponse =
            SQLResponse(await Dio().post(Urls.userUrl, data: formData));

        if (sqlResponse.status == SQLResponseStatusTypes.success) {
          Get.offAll(() => const SignUpOrLogInPage());
          preferences.remove('user');
          clearData();
        }
        return sqlResponse;
      } else {
        myPrint('Dropped userid: ${formData.fields[1]}');
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  ///Validate Log in. Call [setState] after function.
  Future<bool> validate() async {
    SQLResponse? sqlResponse = await get();

    if (sqlResponse?.status == SQLResponseStatusTypes.success &&
        sqlResponse?.user != null) {
      user = sqlResponse!.user!;
      // Retain only for the current process. userToJson deliberately omits it.
      user.password = password;
      preferences.setString('user', userToJson([user]));

      PermissionStatus permissionGranted;
      permissionGranted = await gvLocation.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await gvLocation.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {}
      } else if (permissionGranted == PermissionStatus.granted) {
        LocationData locationData = await gvLocation.getLocation();
        userLocation = LatLng(locationData.latitude!, locationData.longitude!);
      }
      return true;
    } else {
      myPrint(sqlResponse);
      incorrectPassword = true;
      return false;
    }
  }

  ///Check if the email already exists in the database. Returns a list. List[0] returns if email exists. List[1]
  ///returns the [sqlResponse]
  Future<List?> verifyEmail() async {
    try {
      //Json sent to php
      var formData = FormData.fromMap({
        'request': RequestType.get.toString(),
        'userid': email,
        'name': '',
        'email': email,
        'password': '',
        'joinDate': '',
      });

      if (!printInsteadOfPostBool) {
        SQLResponse sqlResponse =
            SQLResponse(await Dio().post(Urls.userUrl, data: formData));
        if (sqlResponse.status == SQLResponseStatusTypes.success) {
          if (null != sqlResponse.user) {
            return [true, sqlResponse];
          } else {
            return [false, null];
          }
        } else {
          return [false, sqlResponse];
        }
      } else {
        myPrint('Find: ${formData.fields}');
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static final google = GoogleSignIn();

  ///Sign up/Log in with google. Call [setState] after function
  ///Only set the userIdNumber when
  static Future<User?> getGoogleAccount() async {
    if (await google.signIn() != null) {
      return User(
          userid: google.currentUser?.displayName
              ?.toLowerCase()
              .removeAllWhitespace,
          name: google.currentUser?.displayName,
          email: google.currentUser?.email,
          joinDate: timeNow,
          password: gAccount);
    } else {
      return null;
    }
  }
}
