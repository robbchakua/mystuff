import 'package:dad_app/utils/constants.dart';
import 'package:dad_app/styles/themes.dart';
import 'package:dad_app/utils/utils.dart';
import 'package:dad_app/widgets/text.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart' hide Title;

class NewUpdatePage extends StatefulWidget {
  const NewUpdatePage({super.key});

  @override
  State<NewUpdatePage> createState() => _NewUpdatePageState();
}

class _NewUpdatePageState extends State<NewUpdatePage> {
  String day = DateFormat.yMMMMd().format(AppDetails.versionDate);
  String t = '      ';
  String n = '        ';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const SubHeader('Changelog'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          width: screenWidth(context),
          color: backgroundColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SubHeader(DateFormat.yMMMMd().format(DateTime(2024, 1, 28))),
              const SubHeader("1.0.0-rc. Release Candidate"),
              const Header('\nBug fixes\n'),
              const BodyText('✓Faster load times.'),
              const BodyText("✓Other 'Under the Hood' changes ."),
              SizedBox(height: screenHeight(context) / 40),
              const Divider(),
              SizedBox(height: screenHeight(context) / 40),
              SubHeader(
                  '${DateFormat.yMMMMd().format(DateTime(2023, 12, 31))} - Happy New Year'),
              const SubHeader("1.0.0-pre_release.002"),
              const Header('\nNew Features\n'),
              const SubHeader("1. Map alignment"),
              BodyText(
                  '$t-Map initialization will place camera in between all other\n'
                  '${n}markers.'),
              const Header('\nHot fixes\n'),
              const BodyText(
                  '✓Log in/Sign up with google button widgets fixed.'),
              const BodyText(
                  '✓Application not adding new items after first one.'),
              SizedBox(height: screenHeight(context) / 40),
              const Divider(),
              SizedBox(height: screenHeight(context) / 40),
              SubHeader(DateFormat.yMMMMd().format(DateTime(2023, 12, 24))),
              const SubHeader("1.0.0-pre_release.001"),
              const Header('\nNew Features\n'),
              const SubHeader("1. Sign up/Log in changes"),
              BodyText('$t-New UI\n$t-You can now sign up with Google which '
                  'means you\n${n}do not need a password to log in.'),
              SizedBox(height: screenHeight(context) / 40),
              const Divider(),
              SizedBox(height: screenHeight(context) / 40),
              SubHeader(DateFormat.yMMMMd().format(DateTime(2023, 12, 21))),
              const SubHeader("1.0.0-pre_release"),
              const Header('\nNew Features\n'),
              const SubHeader('1.  UI Changes'),
              const SubHeader('2. Added a Changelog'),
              BodyText(
                  '$t-Added a changelog to address new features, hotfixes\n       and bugs.'),
              const SubHeader('3. Added Current Location'),
              BodyText('$t-You can now see your location on the map'),
              const SubHeader('4. Removed Categories'),
              BodyText(
                  '$t-Locations are now the main attribute given to an item\n'
                  '$t-You can update and delete locations. Items are bound\n'
                  '${n}to locations so you will have to set a new location or\n'
                  '${n}delete the item when deleting a location.'),
              const Header('\nHotfixes and bugs\n'),
              const BodyText('✓Updated Flutter to 3.16.1'),
            ],
          ),
        ),
      ),
    );
  }
}
