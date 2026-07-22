import 'dart:convert';

import 'package:dad_app/models/item_model.dart';
import 'package:dad_app/models/location_model.dart';
import 'package:dad_app/models/response_model.dart';
import 'package:dad_app/models/user_model.dart';
import 'package:dad_app/utils/utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local user sessions never serialize passwords', () {
    final encoded = userToJson([
      User(
        userid: 'test-user',
        name: 'Test User',
        email: 'test@example.com',
        password: 'do-not-store-this',
        joinDate: DateTime(2024, 1, 1),
      ),
    ]);

    final record = (jsonDecode(encoded) as List).single as Map<String, dynamic>;
    expect(record.containsKey('password'), isFalse);
    expect(encoded, isNot(contains('do-not-store-this')));
  });

  test('legacy session passwords are discarded while parsing', () {
    const legacySession = '[{"userid":"test-user","name":"Test User",'
        '"email":"test@example.com","password":"old-plain-text",'
        '"joinDate":"2024-01-01"}]';

    final user = userFromJson(legacySession).single;

    expect(user.password, isNull);
    expect(user.userid, 'test-user');
  });

  test('authenticated sessions retain role and token without logging secrets',
      () {
    final user = User(
      id: 7,
      userid: 'admin',
      name: 'Admin',
      role: 'admin',
      sessionToken: 'session-secret',
    );

    final restored = userFromJson(userToJson([user])).single;

    expect(restored.isAdmin, isTrue);
    expect(restored.sessionToken, 'session-secret');
    expect(user.toString(), isNot(contains('session-secret')));
  });

  test('items use stable bin ids and server edit permission', () {
    final item = Item.fromJson({
      'id': 10,
      'name': 'Drill',
      'storeDate': '2026-07-22',
      'binId': 4,
      'location': 'Tools',
      'multiple': false,
      'quantity': 1,
      'canEdit': true,
    });

    expect(item.binId, 4);
    expect(item.canEdit, isTrue);
  });

  test('bin paths support unlimited parent nesting', () {
    locationsJsonList = [
      Location(id: 1, name: 'Warehouse'),
      Location(id: 2, parentId: 1, name: 'Shelf'),
      Location(id: 3, parentId: 2, name: 'Blue Box'),
    ];

    expect(
        binDisplayPath(locationsJsonList.last), 'Warehouse / Shelf / Blue Box');
    expect(binDepth(locationsJsonList.last), 2);
  });

  test('structured authorization errors remain readable', () {
    final response = SQLResponse(Response(
      requestOptions: RequestOptions(path: '/post.php'),
      statusCode: 403,
      data: {
        'status': 'forbidden',
        'message': 'You do not have edit access to this bin',
      },
    ));

    expect(response.status, SQLResponseStatusTypes.forbidden);
    expect(response.errorMessage, 'You do not have edit access to this bin');
  });
}
