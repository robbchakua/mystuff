import 'package:flutter/material.dart';

import '../../utils/utils.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(),
        body: SizedBox(
            width: screenWidth(context),
            height: screenHeight(context),
            child: Padding(
                padding: EdgeInsets.all(screenWidth(context) / 20),
                child: Center(
                  child: Text(
                    'Notifications are under development',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: screenWidth(context) / 15),
                  ),
                ))));
  }
}
