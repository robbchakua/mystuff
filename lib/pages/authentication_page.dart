import 'package:dad_app/pages/sign_up_or_log_in_page.dart';
import 'package:dad_app/models/response_model.dart';
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
      await preferences.remove('user');
    }
    final storedUser = preferences.getString('user');
    if (storedUser != null) {
      try {
        final users = userFromJson(storedUser);
        if (users.isEmpty || users.first.sessionToken == null) {
          await preferences.remove('user');
        } else {
          User.user = users.first;
          final response = await User.user.validateSession();
          if (response?.status != SQLResponseStatusTypes.success) {
            await preferences.remove('user');
            User.user = User();
          }
        }
      } catch (_) {
        await preferences.remove('user');
        User.user = User();
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
