import 'package:dad_app/utils/init.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'dart:io';
import '../styles/themes.dart';
import '../utils/utils.dart';

class CameraTest extends StatefulWidget {
  const CameraTest({super.key});

  @override
  State<CameraTest> createState() => _CameraTestState();
}

class _CameraTestState extends State<CameraTest> {
  File file = File("");

  LocationData? currentLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            // Padding(
            //     padding: EdgeInsets.all(screenWidth(context) / 50),
            //     child: ElevatedButton(
            //         onPressed: pickImage,
            //         child: Text(
            //           'Add Image',
            //           style: TextStyle(color: inverseColor(context)),
            //         ))),
            Image.file(
              file,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.image);
              },
            )
          ],
        ),
      ),
    );
  }
}
