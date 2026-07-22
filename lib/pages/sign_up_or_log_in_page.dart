import 'dart:math';
import 'package:dad_app/models/response_model.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:dad_app/styles/themes.dart';
import 'package:dad_app/utils/utils.dart';
import 'package:dad_app/widgets/text.dart';
import 'package:flutter/material.dart' hide Title;
import 'package:flutter_animate/flutter_animate.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'home.dart';

class SignUpOrLogInPage extends StatefulWidget {
  const SignUpOrLogInPage({super.key});

  @override
  State<SignUpOrLogInPage> createState() => _SignUpOrLogInPageState();
}

class _SignUpOrLogInPageState extends State<SignUpOrLogInPage> {
  bool signUp = true;
  bool viewPassword = false;
  TextEditingController passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  List<User> userPass = [];

  //
  //
  // LOGIN
  //
  //
  //
  //
  //

  //
  //
  //Sign UP
  //
  //

  bool isChecked = false;
  bool usernameIsEmpty = true;
  String createdUsername = '';
  TextEditingController signUpPasswordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final signUpFormKey = GlobalKey<FormState>();
  String privacyPolicy =
      'By using the MyStuff service,you agree\nto the terms outlined in the Privacy Policy.';
  bool privacyPolicyError = false;
  int randInt = Random().nextInt(1000);
  String userid = '';

  String createUserId(String name) {
    final normalized = name
        .toLowerCase()
        .removeAllWhitespace
        .replaceAll(RegExp(r'[^a-z0-9._-]'), '');
    return normalized.isEmpty ? 'user' : normalized;
  }

  void createNewRandint() {
    setState(() {
      randInt = Random().nextInt(1000);
      createdUsername = '';
      _usernameController.text = '';
    });
  }

  Future confirmExit() => showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: const Title('Alert'),
            content: const Header('Do you want to exit?'),
            actions: [
              TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    pop();
                  },
                  child: const ButtonText('Yes')),
              TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                  child: const ButtonText('No')),
            ],
          ));

  static Future<void> pop({bool? animated}) async {
    await SystemChannels.platform
        .invokeMethod<void>('SystemNavigator.pop', animated);
  }

//
  //
  //
  //
  //
  // CODE
  //
  //
  //
  //
  //
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final value = await confirmExit();
        if (value != null) {
          return Future.value(value);
        } else {
          return Future.value(false);
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: backgroundColor,
        body: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: signUp
                              ? const BorderRadius.only(
                                  topRight: Radius.circular(30))
                              : const BorderRadius.only(
                                  topLeft: Radius.circular(30))),
                      width: screenWidth(context) / 1.98,
                      height: screenHeight(context) / 19.6,
                    ).animate(target: !signUp ? 1 : 0).moveX(
                        begin: -(screenWidth(context) / 4),
                        end: screenWidth(context) / 4,
                        duration: const Duration(milliseconds: 170)),
                    Align(
                      alignment:
                          signUp ? Alignment.bottomLeft : Alignment.bottomRight,
                      child: Divider(
                        height: screenHeight(context) / 750,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      width: screenWidth(context) / 2,
                      height: screenHeight(context) / 20,
                      decoration: BoxDecoration(
                          color: primaryColor(context),
                          borderRadius: signUp
                              ? const BorderRadius.only(
                                  topRight: Radius.circular(30))
                              : const BorderRadius.only(
                                  topLeft: Radius.circular(30))),
                    ).animate(target: !signUp ? 1 : 0).moveX(
                        begin: -(screenWidth(context) / 4),
                        end: screenWidth(context) / 4,
                        duration: const Duration(milliseconds: 170)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        TextButton(
                          style: ButtonStyle(
                              padding: MaterialStateProperty.all(
                                  EdgeInsets.only(
                                      top: screenHeight(context) / 40))),
                          onPressed: () => {
                            pageViewController.previousPage(
                                duration: const Duration(milliseconds: 170),
                                curve: Animate.defaultCurve)
                          },
                          child: const Header('Sign Up')
                              .animate(target: !signUp ? 1 : 0)
                              .scaleXY(
                                  end: 0.6,
                                  duration: const Duration(milliseconds: 170)),
                        ),
                        TextButton(
                          style: ButtonStyle(
                              padding: MaterialStateProperty.all(
                                  EdgeInsets.only(
                                      top: screenHeight(context) / 40))),
                          onPressed: () => {
                            pageViewController.nextPage(
                                duration: const Duration(milliseconds: 170),
                                curve: Animate.defaultCurve)
                          },
                          child: const Header('Log In')
                              .animate(target: signUp ? 1 : 0)
                              .scaleXY(
                                  end: 0.6,
                                  duration: const Duration(milliseconds: 170)),
                        )
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  width: screenWidth(context),
                  height: screenHeight(context) / 1.5,
                  child: PageView(
                    controller: pageViewController,
                    scrollDirection: Axis.horizontal,
                    onPageChanged: (page) {
                      if (page == 0) {
                        setState(() {
                          signUp = true;
                        });
                      } else {
                        setState(() {
                          signUp = false;
                        });
                      }
                    },
                    children: [
                      //
                      //
                      //
                      //
                      // SIGN UP
                      //
                      //
                      //
                      //
                      //
                      Container(
                          color: primaryColor(context),
                          child: SizedBox(
                            height: screenHeight(context) / 2,
                            width: screenWidth(context),
                            child: Padding(
                                padding:
                                    EdgeInsets.all(screenHeight(context) / 30),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Form(
                                      key: signUpFormKey,
                                      child: Column(
                                        children: [
                                          Padding(
                                              padding: EdgeInsets.symmetric(
                                                  vertical:
                                                      screenHeight(context) /
                                                          80),
                                              child: Row(
                                                children: [
                                                  SizedBox(
                                                    width:
                                                        screenWidth(context) /
                                                            2.5,
                                                    child: TextFormField(
                                                      autofillHints: const [
                                                        AutofillHints
                                                            .newUsername
                                                      ],
                                                      keyboardType:
                                                          TextInputType.name,
                                                      onChanged: (value) {
                                                        if (value == '') {
                                                          setState(() {
                                                            createdUsername =
                                                                '';
                                                            usernameIsEmpty =
                                                                true;
                                                          });
                                                        } else {
                                                          setState(() {
                                                            usernameIsEmpty =
                                                                false;
                                                            createdUsername =
                                                                ('${createUserId(value)}$randInt');
                                                          });
                                                        }
                                                      },
                                                      controller:
                                                          _usernameController,
                                                      textAlignVertical:
                                                          TextAlignVertical
                                                              .center,
                                                      validator: (value) {
                                                        if (value!.isEmpty) {
                                                          return InputErrors
                                                              .emptyUsername;
                                                        } else {
                                                          if (value.length >
                                                              20) {
                                                            return InputErrors
                                                                .longName;
                                                          } else {
                                                            return null;
                                                          }
                                                        }
                                                      },
                                                      decoration:
                                                          const InputDecoration(
                                                              labelText: 'Name',
                                                              suffixIcon: Icon(
                                                                  Icons
                                                                      .person)),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                      width:
                                                          screenWidth(context) /
                                                              18.7),
                                                  Padding(
                                                      padding: EdgeInsets.symmetric(
                                                          vertical:
                                                              screenHeight(
                                                                      context) /
                                                                  200),
                                                      child: SizedBox(
                                                        width: screenWidth(
                                                                context) /
                                                            2.5,
                                                        child: TextFormField(
                                                          readOnly: true,
                                                          textAlignVertical:
                                                              TextAlignVertical
                                                                  .center,
                                                          decoration:
                                                              InputDecoration(
                                                                  hintStyle: TextStyle(
                                                                      color: usernameIsEmpty
                                                                          ? middleGrey(
                                                                              context)
                                                                          : inverseColor(
                                                                              context)),
                                                                  hintText:
                                                                      createdUsername,
                                                                  labelText:
                                                                      'Username',
                                                                  suffixIcon:
                                                                      IconButton(
                                                                          onPressed:
                                                                              () {
                                                                            createNewRandint();
                                                                          },
                                                                          icon:
                                                                              const Icon(Icons.refresh_outlined))),
                                                        ),
                                                      )),
                                                ],
                                              )),
                                          Padding(
                                              padding: EdgeInsets.symmetric(
                                                  vertical:
                                                      screenHeight(context) /
                                                          100),
                                              child: SizedBox(
                                                width: screenWidth(context),
                                                child: TextFormField(
                                                  autofillHints: const [
                                                    AutofillHints.password,
                                                    AutofillHints.newPassword
                                                  ],
                                                  controller:
                                                      signUpPasswordController,
                                                  obscureText: !viewPassword,
                                                  validator: (value) {
                                                    if (value!.isEmpty) {
                                                      return InputErrors
                                                          .emptyPassword;
                                                    } else {
                                                      if (!InputErrors
                                                          .uppercaseChars
                                                          .hasMatch(value)) {
                                                        return InputErrors
                                                            .missingUppercase;
                                                      } else if (!InputErrors
                                                          .numberChars
                                                          .hasMatch(value)) {
                                                        return InputErrors
                                                            .missingNumber;
                                                      } else if (!InputErrors
                                                          .specialChars
                                                          .hasMatch(value)) {
                                                        return InputErrors
                                                            .missingSpecialChar;
                                                      } else if (value.length <
                                                          10) {
                                                        return InputErrors
                                                            .shortPassword;
                                                      } else {
                                                        return null;
                                                      }
                                                    }
                                                  },
                                                  obscuringCharacter: '•',
                                                  textAlignVertical:
                                                      TextAlignVertical.center,
                                                  decoration: InputDecoration(
                                                      labelText: 'Password',
                                                      suffixIcon: IconButton(
                                                          onPressed: () {
                                                            if (viewPassword) {
                                                              setState(() {
                                                                viewPassword =
                                                                    false;
                                                              });
                                                            } else {
                                                              setState(() {
                                                                viewPassword =
                                                                    true;
                                                              });
                                                            }
                                                          },
                                                          icon: !viewPassword
                                                              ? const Icon(Icons
                                                                  .visibility_off)
                                                              : const Icon(Icons
                                                                  .visibility))),
                                                ),
                                              )),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Checkbox(
                                          activeColor: Colors.blue,
                                          checkColor: Colors.white,
                                          value: isChecked,
                                          onChanged: (newValue) {
                                            setState(() {
                                              isChecked = newValue!;
                                            });
                                          },
                                        ),
                                        Text(
                                          privacyPolicy.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: screenWidth(context) / 49,
                                            color: privacyPolicyError
                                                ? Colors.red
                                                : inverseColor(context),
                                          ),
                                        )
                                      ],
                                    ),
                                    Padding(
                                        padding: EdgeInsets.symmetric(
                                            vertical:
                                                screenHeight(context) / 40),
                                        child: TextButton(
                                          onPressed: () async {
                                            if (signUpFormKey.currentState!
                                                .validate()) {
                                              if (isChecked) {
                                                String name =
                                                    _usernameController.text;
                                                setState(() {
                                                  privacyPolicyError = false;
                                                  processing = true;
                                                  privacyPolicy =
                                                      'By using the MyStuff service,you agree\nto the terms outlined in the Privacy Policy.';
                                                });
                                                SQLResponse? sqlPost = await User(
                                                        userid: createdUsername,
                                                        name: name,
                                                        email: 'NO-EMAIL',
                                                        password:
                                                            signUpPasswordController
                                                                .text,
                                                        joinDate: timeNow)
                                                    .post(false);

                                                if (sqlPost != null &&
                                                    sqlPost.status ==
                                                        SQLResponseStatusTypes
                                                            .success) {
                                                  setState(() {
                                                    processing = false;
                                                  });
                                                  Get.offAll(
                                                      () => const Home());
                                                } else {
                                                  setState(() {
                                                    processing = false;
                                                  });
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(SnackBar(
                                                            content: BodyText(sqlPost
                                                                    ?.errorMessage ??
                                                                'Could not create account')));
                                                  }
                                                }
                                              } else {
                                                setState(() {
                                                  privacyPolicyError = true;
                                                  privacyPolicy =
                                                      'Accept the privacy policy';
                                                });
                                              }
                                            }
                                          },
                                          style: ButtonStyle(
                                              side: MaterialStateProperty.all(
                                                  const BorderSide(
                                                      style: BorderStyle.solid,
                                                      color: Colors.white)),
                                              padding: MaterialStateProperty
                                                  .all(EdgeInsets.symmetric(
                                                      vertical:
                                                          screenWidth(context) /
                                                              50,
                                                      horizontal:
                                                          screenWidth(context) /
                                                              5)),
                                              backgroundColor:
                                                  MaterialStateProperty.all(
                                                      backgroundColor)),
                                          child: SubHeader(
                                            'Sign Up'.toUpperCase(),
                                          ),
                                        )),
                                  ],
                                )),
                          )),
                      //
                      //
                      //
                      //
                      //
                      //LogIN
                      //
                      //
                      //
                      //
                      //
                      Container(
                        color: primaryColor(context),
                        child: SizedBox(
                          height: screenHeight(context) / 2,
                          width: screenWidth(context),
                          child: Padding(
                              padding:
                                  EdgeInsets.all(screenHeight(context) / 30),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Form(
                                    key: formKey,
                                    child: Column(
                                      children: [
                                        Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical:
                                                    screenHeight(context) / 40),
                                            child: TextFormField(
                                              autofillHints: const [
                                                AutofillHints.username
                                              ],
                                              validator: (value) {
                                                if (value!.isEmpty) {
                                                  return 'Name/Email cannot be empty';
                                                } else if (userNotFound) {
                                                  return "Name/Email does not exist";
                                                } else {
                                                  return null;
                                                }
                                              },
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              controller: usernameController,
                                              textAlignVertical:
                                                  TextAlignVertical.center,
                                              decoration: const InputDecoration(
                                                  labelText: 'Name/Email',
                                                  suffixIcon:
                                                      Icon(Icons.person)),
                                            )),
                                        Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical:
                                                    screenHeight(context) /
                                                        100),
                                            child: TextFormField(
                                              autofillHints: const [
                                                AutofillHints.password
                                              ],
                                              validator: (value) {
                                                if (value!.isEmpty) {
                                                  return 'Password cannot be empty';
                                                } else if (incorrectPassword) {
                                                  return "Incorrect Password";
                                                } else {
                                                  return null;
                                                }
                                              },
                                              controller: passwordController,
                                              obscureText: !viewPassword,
                                              obscuringCharacter: '•',
                                              textAlignVertical:
                                                  TextAlignVertical.center,
                                              decoration: InputDecoration(
                                                  labelText: 'Password',
                                                  suffixIcon: IconButton(
                                                      onPressed: () {
                                                        if (viewPassword) {
                                                          setState(() {
                                                            viewPassword =
                                                                false;
                                                          });
                                                        } else {
                                                          setState(() {
                                                            viewPassword = true;
                                                          });
                                                        }
                                                      },
                                                      icon: !viewPassword
                                                          ? const Icon(Icons
                                                              .visibility_off)
                                                          : const Icon(Icons
                                                              .visibility))),
                                            )),
                                      ],
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton(
                                      onPressed: () {},
                                      child: Text(
                                        'Forgot Password?(In Dev)'
                                            .toUpperCase(),
                                        style: TextStyle(
                                            fontSize: screenWidth(context) / 39,
                                            color: inverseColor(context)),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: screenHeight(context) / 40),
                                      child: TextButton(
                                        onPressed: () async {
                                          setState(() {
                                            userNotFound = false;
                                            incorrectPassword = false;
                                            processing = true;
                                          });
                                          User newUser = User(
                                            name: '',
                                            userid: usernameController.text,
                                            email: usernameController.text,
                                            password: passwordController.text,
                                          );
                                          bool sqlGet =
                                              await newUser.validate();
                                          setState(() {});

                                          if (sqlGet) {
                                            Get.offAll(() => const Home());
                                            setState(() {
                                              processing = false;
                                            });
                                          } else {
                                            formKey.currentState!.validate();
                                            setState(() {
                                              processing = false;
                                            });
                                          }
                                        },
                                        style: ButtonStyle(
                                            side: MaterialStateProperty.all(
                                                const BorderSide(
                                                    style: BorderStyle.solid,
                                                    color: Colors.white)),
                                            padding: MaterialStateProperty.all(
                                                EdgeInsets.symmetric(
                                                    vertical:
                                                        screenWidth(context) /
                                                            50,
                                                    horizontal:
                                                        screenWidth(context) /
                                                            5)),
                                            backgroundColor:
                                                MaterialStateProperty.all(
                                                    backgroundColor)),
                                        child: SubHeader(
                                          'Log In'.toUpperCase(),
                                        ),
                                      )),
                                ],
                              )),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
            processing
                ? Container(
                    height: screenHeight(context),
                    width: screenWidth(context),
                    color: const Color(0xAA000000),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: inverseColor(context)),
                        SubHeader(signUp
                            ? 'Creating you an account...'
                            : 'Attempting to Log you in...')
                      ],
                    ),
                  )
                : const SizedBox(
                    height: 0,
                    width: 0,
                  ),
            Align(
              alignment: Alignment.bottomRight,
              child: VersionText(AppDetails.version),
            )
          ],
        ),
      ),
    );
  }
}
