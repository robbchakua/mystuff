import 'package:dad_app/styles/themes.dart';
import 'package:flutter/material.dart';
import '../utils/utils.dart';

class TextTesting extends StatelessWidget {
  const TextTesting({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: screenHeight(context) - screenHeightWithSafeArea(context),
          ),
          SizedBox(
            height: screenHeightWithSafeArea(context),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Title('This is a Title'),
                const Header('This is a Header'),
                const SubHeader('This is a Sub Header'),
                const BodyText(
                    "MyStuff is designed to track the physical location of items. \n"
                    "This is BodyText"),
                ElevatedButton(
                    onPressed: () {},
                    child: const ButtonText('This is Button Text'))
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Title extends Text {
  const Title(super.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(data ?? "",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: screenWidth(context) / 13,
          color: inverseColor(context),
          fontWeight: FontWeight.bold,
        ));
  }
}

class Header extends Text {
  const Header(super.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(data ?? "",
        style: TextStyle(
          fontSize: screenWidth(context) / 15,
          color: inverseColor(context),
          fontWeight: FontWeight.w800,
        ));
  }
}

class SubHeader extends Text {
  const SubHeader(super.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(data ?? "",
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: screenWidth(context) / 25,
          color: inverseColor(context),
          fontWeight: FontWeight.w800,
        ));
  }
}

class BodyText extends Text {
  const BodyText(super.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(data ?? "",
        style: TextStyle(
            color: inverseColor(context),
            fontSize: screenWidth(context) / 30,
            fontWeight: FontWeight.w300));
  }
}

class ButtonText extends Text {
  const ButtonText(super.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(data ?? "",
        style: TextStyle(
          color: inverseColor(context),
          fontSize: screenWidth(context) / 30,
        ));
  }
}

class VersionText extends Text {
  const VersionText(super.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(data ?? "",
        style: TextStyle(
          color: Colors.grey,
          fontSize: screenWidth(context) / 30,
        ));
  }
}
