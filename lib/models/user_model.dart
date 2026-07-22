import 'dart:convert';

import 'package:dad_app/models/response_model.dart';
import 'package:dad_app/pages/sign_up_or_log_in_page.dart';
import 'package:dad_app/utils/constants.dart';
import 'package:dad_app/utils/api.dart';
import 'package:dad_app/utils/init.dart';
import 'package:dad_app/utils/utils.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

List<User> userFromJson(String str) => List<User>.from(
    (json.decode(str) as List).map((value) => User.fromJson(value)));

String userToJson(List<User> data) =>
    json.encode(data.map((user) => user.toJson()).toList());

class User {
  int? id;
  String? userid;
  String? name;
  String? email;
  String? password;
  String? role;
  String? sessionToken;
  bool? isActive;
  DateTime? joinDate;

  User({
    this.id,
    this.userid,
    this.name,
    this.email,
    this.password,
    this.role,
    this.sessionToken,
    this.isActive,
    this.joinDate,
  });

  static User user = User();

  bool get isAdmin => role == 'admin';

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: _asInt(json['id']),
        userid: json['userid']?.toString(),
        name: json['name']?.toString(),
        email: json['email']?.toString() ?? 'NO-EMAIL',
        password: null,
        role: json['role']?.toString() ?? 'observer',
        sessionToken: json['sessionToken']?.toString(),
        isActive: _asBool(json['isActive'], fallback: true),
        joinDate: DateTime.tryParse(json['joinDate']?.toString() ?? ''),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userid': userid,
        'name': name,
        'email': email,
        'role': role,
        'sessionToken': sessionToken,
        'isActive': isActive,
        'joinDate': joinDate == null
            ? null
            : '${joinDate!.year.toString().padLeft(4, '0')}-'
                '${joinDate!.month.toString().padLeft(2, '0')}-'
                '${joinDate!.day.toString().padLeft(2, '0')}',
      };

  @override
  String toString() =>
      'User(UserId: $userid, Name: $name, Email: $email, Role: $role, '
      'Password: [redacted], Session: [redacted])';

  /// Creates the first administrator, or a team member when called by an
  /// already authenticated administrator.
  Future<SQLResponse?> post([bool unusedGoogleFlag = false]) async {
    try {
      final formData = FormData.fromMap({
        'request': RequestType.postUser.toString(),
        'token': User.user.sessionToken,
        'userid': userid,
        'name': name,
        'email': email == 'NO-EMAIL' ? '' : email,
        'password': password,
        'role': role ?? 'observer',
      });
      if (printInsteadOfPostBool) {
        myPrint('Post user: ${formData.fields.map((e) => e.key)}');
        return null;
      }

      final sqlResponse =
          SQLResponse(await apiClient.post(Urls.userUrl, data: formData));
      final createdUser = sqlResponse.user;
      if (sqlResponse.status == SQLResponseStatusTypes.success &&
          createdUser?.sessionToken != null) {
        user = createdUser!;
        await preferences.setString('user', userToJson([user]));
        await _loadLocationPermission();
      }
      return sqlResponse;
    } catch (error) {
      myPrint(error);
      return null;
    }
  }

  Future<SQLResponse?> put({String? newPassword}) async {
    try {
      final formData = FormData.fromMap({
        'request': RequestType.putUser.toString(),
        'token': User.user.sessionToken,
        'userId': id ?? User.user.id,
        'name': name,
        'email': email == 'NO-EMAIL' ? '' : email,
        'role': role ?? User.user.role,
        'isActive': isActive ?? User.user.isActive,
        'newPassword': newPassword ?? '',
      });
      if (printInsteadOfPostBool) {
        myPrint('Update user: ${formData.fields.map((e) => e.key)}');
        return null;
      }

      final sqlResponse =
          SQLResponse(await apiClient.post(Urls.userUrl, data: formData));
      if (sqlResponse.status == SQLResponseStatusTypes.success &&
          (id == null || id == User.user.id) &&
          sqlResponse.user != null) {
        final token = User.user.sessionToken;
        User.user = sqlResponse.user!..sessionToken = token;
        await preferences.setString('user', userToJson([User.user]));
      }
      return sqlResponse;
    } catch (error) {
      myPrint(error);
      return null;
    }
  }

  Future<SQLResponse?> get() async {
    try {
      final formData = FormData.fromMap({
        'request': RequestType.login.toString(),
        'userid': userid ?? email,
        'email': email,
        'password': password,
      });
      if (printInsteadOfPostBool) {
        myPrint('Login requested for $userid');
        return null;
      }
      return SQLResponse(await apiClient.post(Urls.userUrl, data: formData));
    } catch (error) {
      myPrint(error);
      return null;
    }
  }

  Future<SQLResponse?> validateSession() async {
    try {
      final response = SQLResponse(await apiClient.post(
        Urls.userUrl,
        data: FormData.fromMap({
          'request': RequestType.session.toString(),
          'token': sessionToken,
        }),
      ));
      if (response.status == SQLResponseStatusTypes.success &&
          response.user != null) {
        final token = sessionToken;
        user = response.user!..sessionToken = token;
        await preferences.setString('user', userToJson([user]));
      }
      return response;
    } catch (error) {
      myPrint(error);
      return null;
    }
  }

  Future<void> logout() async {
    final token = User.user.sessionToken;
    if (token != null && token.isNotEmpty) {
      try {
        await apiClient.post(
          Urls.userUrl,
          data: FormData.fromMap({
            'request': RequestType.logout.toString(),
            'token': token,
          }),
        );
      } catch (error) {
        myPrint(error);
      }
    }
    await preferences.remove('user');
    clearData();
  }

  Future<SQLResponse?> drop({String? currentPassword}) async {
    try {
      final formData = FormData.fromMap({
        'request': RequestType.dropUser.toString(),
        'token': User.user.sessionToken,
        'userId': id ?? User.user.id,
        'password': currentPassword,
      });
      if (printInsteadOfPostBool) {
        myPrint('Delete user requested');
        return null;
      }
      final sqlResponse =
          SQLResponse(await apiClient.post(Urls.userUrl, data: formData));
      if (sqlResponse.status == SQLResponseStatusTypes.success &&
          (id == null || id == User.user.id)) {
        await preferences.remove('user');
        clearData();
        Get.offAll(() => const SignUpOrLogInPage());
      }
      return sqlResponse;
    } catch (error) {
      myPrint(error);
      return null;
    }
  }

  Future<bool> validate() async {
    final sqlResponse = await get();
    if (sqlResponse?.status == SQLResponseStatusTypes.success &&
        sqlResponse?.user?.sessionToken != null) {
      user = sqlResponse!.user!;
      await preferences.setString('user', userToJson([user]));
      await _loadLocationPermission();
      return true;
    }
    incorrectPassword = true;
    return false;
  }

  /// Retained for the profile email editor. The server performs the real
  /// uniqueness check again when the account is updated.
  Future<List?> verifyEmail() async {
    try {
      final response = SQLResponse(await apiClient.post(
        Urls.userUrl,
        data: FormData.fromMap({
          'request': RequestType.emailCheck.toString(),
          'token': User.user.sessionToken,
          'email': email,
        }),
      ));
      if (response.status != SQLResponseStatusTypes.success) {
        return [false, response];
      }
      return [response.emailExists, response.emailExists ? response : null];
    } catch (error) {
      myPrint(error);
      return null;
    }
  }

  static Future<SQLResponse?> listTeam() async {
    try {
      return SQLResponse(await apiClient.post(
        Urls.userUrl,
        data: FormData.fromMap({
          'request': RequestType.listUsers.toString(),
          'token': User.user.sessionToken,
        }),
      ));
    } catch (error) {
      myPrint(error);
      return null;
    }
  }

  static Future<void> _loadLocationPermission() async {
    PermissionStatus permission = await gvLocation.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await gvLocation.requestPermission();
    }
    if (permission == PermissionStatus.granted) {
      final locationData = await gvLocation.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        userLocation = LatLng(locationData.latitude!, locationData.longitude!);
      }
    }
  }
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  return int.tryParse(value.toString());
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value.toLowerCase() == 'true' || value == '1';
  return fallback;
}
