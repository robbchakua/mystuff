import 'package:cached_network_image/cached_network_image.dart';
import 'package:dad_app/models/location_model.dart';
import 'package:dad_app/utils/utils.dart';
import 'package:flutter/material.dart';

//PUSHED TO 1.0.1-release

class LocationMarker extends StatelessWidget {
  final Location location;
  final String imageLocation;

  const LocationMarker(
      {super.key, required this.location, required this.imageLocation});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: screenWidth(context) / 20,
          backgroundColor: stringToColor(location.color!),
          child: CircleAvatar(
            radius: screenWidth(context) / 25,
            backgroundImage: CachedNetworkImageProvider(imageLocation),
          ),
        ),
        Padding(
            padding: EdgeInsets.only(top: screenHeight(context) / 21),
            child: Icon(
              Icons.arrow_drop_down,
              color: stringToColor(location.color!),
              size: screenWidth(context) / 6,
            )),
      ],
    );
  }
}
