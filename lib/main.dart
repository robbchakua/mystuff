import 'dart:io';
import 'package:dad_app/pages/authentication_page.dart';
import 'package:dad_app/pages/new_update_page.dart';
import 'package:dad_app/utils/init.dart';
import 'package:dad_app/styles/themes.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Response;
import 'package:flutter/material.dart' hide Key;
import 'package:window_size/window_size.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPreferences(
      print: false,
      printInsteadOfPost: false,
      resetUserData: false,
      showTestingItems: false,
      developingPage: false,
      page: const NewUpdatePage());

  if (Platform.isWindows) {
    setWindowMinSize(const Size(1366, 768));
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return GetMaterialApp(
      defaultTransition: Transition.noTransition,
      theme: darkTheme(context),
      home: const AuthenticationPage(),
    );
  }
}
