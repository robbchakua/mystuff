import 'dart:convert';

import 'package:dad_app/models/user_model.dart';
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
}
