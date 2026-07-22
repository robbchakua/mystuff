import 'package:dad_app/pages/settings/about_us_page.dart';
import 'package:dad_app/pages/settings/privacy_page.dart';
import 'package:dad_app/pages/sign_up_or_log_in_page.dart';
import 'package:dad_app/utils/constants.dart';
import 'package:dad_app/utils/init.dart';
import 'package:dad_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/user_model.dart';
import '../styles/google_maps_styles.dart';
import '../styles/themes.dart';
import 'package:get/get.dart';
import '../widgets/text.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    makeUserVariable();
    super.initState();
  }

  void hasEmail() {
    if (User.user.email! != 'NO-EMAIL') {
      setState(() {
        hasEmailBool = true;
      });
    }
  }

  void makeUserVariable() async {
    Object? userString = preferences.get('user');
    List<User> tempList = [];
    setState(() {
      tempList = userFromJson(userString.toString());
      User.user = tempList[0];
      firstName = User.user.name!.split(" ").first;
    });
    hasEmail();
  }

  @override
  void dispose() {
    formKey.currentState?.dispose();
    super.dispose();
  }

  Future logOutWarning() => showDialog(
      context: context,
      builder: (context) => AlertDialog(
            icon: const Icon(
              Icons.warning,
              color: Colors.yellow,
            ),
            title: const Text('Are you sure?'),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  clearData();
                  Get.offAll(() => const SignUpOrLogInPage());
                  preferences.remove('user');
                  preferences.remove('settings');
                },
                child: Text('Yes',
                    style: TextStyle(
                        color: inverseColor(context),
                        fontWeight: FontWeight.w300)),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                },
                child: Text('No',
                    style: TextStyle(
                        color: inverseColor(context),
                        fontWeight: FontWeight.w300)),
              ),
            ],
          ));

  Future deleteAccount() => showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: const SubHeader('Delete Account'),
            content: Form(
                key: formKey,
                child: TextFormField(
                  controller: emailController,
                  validator: (val) {
                    if (val!.isEmpty) {
                      return InputErrors.emptyPassword;
                    }
                    return null;
                  },
                  obscuringCharacter: '•',
                  obscureText: true,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: const InputDecoration(
                      suffixIcon: Icon(Icons.password), labelText: 'Password'),
                )),
            actions: [
              ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.red)),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      await User.user
                          .drop(currentPassword: emailController.text);
                    }
                  },
                  child: Text(
                    'Delete account',
                    style: TextStyle(color: inverseColor(context)),
                  )),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel',
                      style: TextStyle(color: inverseColor(context)))),
            ],
          ));

  Future emailInUseError() => showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: const SubHeader('Error'),
            content: SubHeader('${emailController.text}\nalready in use'),
            actions: [
              ElevatedButton(
                  onPressed: () => {Navigator.pop(context)},
                  child: const ButtonText('Okay'))
            ],
          ));

  Future addEmail() => showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: const Text('Add Email'),
            content: Form(
                key: formKey,
                child: TextFormField(
                  controller: emailController,
                  validator: (val) {
                    if (val!.isEmpty) {
                      return InputErrors.emptyEmail;
                    } else {
                      if (!InputErrors.emailChars.hasMatch(val)) {
                        return InputErrors.emailError;
                      } else {
                        return null;
                      }
                    }
                  },
                  keyboardType: TextInputType.emailAddress,
                  textAlignVertical: TextAlignVertical.center,
                  decoration:
                      const InputDecoration(suffixIcon: Icon(Icons.email)),
                )),
            actions: [
              ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      User putUser = User(
                          userid: User.user.userid!,
                          name: User.user.name!,
                          email: emailController.text,
                          password: User.user.password);

                      List? email = await putUser.verifyEmail();

                      if (email != null) {
                        bool emailExist = email[0];
                        if (emailExist) {
                          emailInUseError();
                        } else if (email[1] != null) {
                          putUser.put();
                          setState(() {});
                          Navigator.pop(context);
                        }
                      }
                    }
                  },
                  child: Text(
                    'Add Email',
                    style: TextStyle(color: inverseColor(context)),
                  )),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel',
                      style: TextStyle(color: inverseColor(context)))),
            ],
          ));

  bool isSelected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(),
      body: Container(
        color: backgroundColor,
        child: SizedBox(
          width: screenWidth(context),
          height: screenHeight(context),
          child: Padding(
            padding: EdgeInsets.all(screenWidth(context) / 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RawMaterialButton(
                      onPressed: () {
                        // if (!isSelected) {
                        //   setState(() {
                        //     isSelected = true;
                        //   });
                        // } else {
                        //   myPrint('Open Edit Image');
                        //   Get.to(() => const Home());
                        // }
                      },
                      child: CircleAvatar(
                        radius: screenWidth(context) / 7.9,
                        backgroundColor: inverseColor(context),
                        child: CircleAvatar(
                            backgroundColor: !isSelected
                                ? secondaryColor(context)
                                : primaryColor(context),
                            radius: screenWidth(context) / 8,
                            child: !isSelected
                                ? Center(
                                    child: Icon(Icons.person,
                                        size: screenWidth(context) / 5,
                                        color: inverseColor(context)),
                                  )
                                : Center(
                                    child: Icon(Icons.edit,
                                        size: screenWidth(context) / 10,
                                        color: inverseColor(context)),
                                  )),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          User.user.name!,
                          style: TextStyle(
                            fontSize: screenWidth(context) / 15,
                            color: inverseColor(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                            onPressed: () {},
                            icon: Icon(
                              Icons.edit,
                              size: screenHeight(context) / 50,
                            ))
                      ],
                    ),
                    hasEmailBool
                        ? Row(
                            children: [
                              Text(
                                User.user.email!,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                    fontWeight: FontWeight.w300,
                                    fontSize: screenWidth(context) / 30,
                                    color: inverseColor(context)),
                              ),
                              IconButton(
                                  onPressed: () {},
                                  icon: Icon(
                                    Icons.edit,
                                    size: screenHeight(context) / 50,
                                  ))
                            ],
                          )
                        : SizedBox(
                            width: screenWidth(context) / 3.282,
                            child: TextButton(
                                onPressed: () {
                                  addEmail();
                                },
                                style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.all(
                                        primaryColor(context))),
                                child: Row(
                                  children: [
                                    Text(
                                      'Add email',
                                      style: TextStyle(
                                          color: inverseColor(context)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(
                                          left: screenWidth(context) / 55),
                                      child: const Icon(Icons.warning,
                                          color: Colors.yellow),
                                    )
                                  ],
                                )),
                          ),
                    Text(
                      User.user.userid!,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: screenWidth(context) / 30,
                        color: inverseColor(context),
                      ),
                    ),
                    Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: screenHeight(context) / 500),
                        child: const Divider()),
                    Stack(
                      children: [
                        const SubHeader('Map'),
                        Padding(
                          padding: EdgeInsets.only(
                              left: screenWidth(context) / 10,
                              top: screenHeight(context) / 350),
                          child: const Divider(),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                            padding: EdgeInsets.all(screenWidth(context) / 150),
                            child: const BodyText('Transitions')),
                        Padding(
                            padding: EdgeInsets.all(screenWidth(context) / 150),
                            child: Switch(
                              value: transitionMap,
                              activeTrackColor: Colors.blueAccent,
                              activeColor: Colors.white,
                              onChanged: (value) {
                                List<String>? myList =
                                    preferences.getStringList('settings');
                                setState(() {
                                  myList?[0] = value.toString();
                                  transitionMap = value;
                                });
                                preferences.setStringList('settings', myList!);
                              },
                            )),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                            padding: EdgeInsets.all(screenWidth(context) / 150),
                            child: const BodyText('Dark mode')),
                        Padding(
                            padding: EdgeInsets.all(screenWidth(context) / 150),
                            child: Switch(
                              value: darkModeMap,
                              activeTrackColor: Colors.blueAccent,
                              activeColor: Colors.white,
                              onChanged: (value) async {
                                GoogleMapController controller =
                                    await googleMapsController.future;
                                List<String>? myList =
                                    preferences.getStringList('settings');
                                setState(() {
                                  myList?[1] = value.toString();
                                  darkModeMap = value;
                                });
                                preferences.setStringList('settings', myList!);
                                if (value) {
                                  controller.setMapStyle(googleMapsDarkMode);
                                } else {
                                  controller.setMapStyle(googleMapsLightMode);
                                }
                              },
                            )),
                      ],
                    ),
                    const Divider(),
                    ElevatedButton(
                      onPressed: () {
                        Get.to(() => const PrivacyPage());
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          const Icon(Icons.shield),
                          Text('Privacy Policy',
                              style: TextStyle(
                                  color: inverseColor(context),
                                  fontWeight: FontWeight.w300))
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Get.to(() => const AboutUsPage());
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          const Icon(Icons.info),
                          Text('About us',
                              style: TextStyle(
                                  color: inverseColor(context),
                                  fontWeight: FontWeight.w300))
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        logOutWarning();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          const Icon(Icons.logout),
                          Text('Log Out',
                              style: TextStyle(
                                  color: inverseColor(context),
                                  fontWeight: FontWeight.w300))
                        ],
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.red)),
                  onPressed: deleteAccount,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const Icon(Icons.delete_forever),
                      Text('Delete Account',
                          style: TextStyle(
                              color: inverseColor(context),
                              fontWeight: FontWeight.w300))
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
