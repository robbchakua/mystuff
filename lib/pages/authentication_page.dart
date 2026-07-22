import 'package:dad_app/pages/sign_up_or_log_in_page.dart';
import 'package:dad_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../styles/themes.dart';
import 'home.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key});

  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  @override
  void initState() {
    userInit();
    super.initState();
  }

  Future userInit() async {
    preferences = await SharedPreferences.getInstance();
    if (resetUserDataBool) {
      preferences.remove('user');
      User.google.signOut();
    }
    final storedUser = preferences.getString('user');
    if (storedUser != null) {
      try {
        // Re-save legacy sessions without the old plain-text password field.
        final users = userFromJson(storedUser);
        preferences.setString('user', userToJson(users));
      } catch (_) {
        preferences.remove('user');
      }
    }
    if (preferences.getString('user') != null) {
      Get.offAll(() => developingPageBool ? developingPageWidget : const Home(),
          transition: Transition.circularReveal);
    } else {
      Get.offAll(
          () => developingPageBool
              ? developingPageWidget
              : const SignUpOrLogInPage(),
          transition: Transition.circularReveal);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: screenHeightWithSafeArea(context),
      width: screenWidth(context),
      color: backgroundColor,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
