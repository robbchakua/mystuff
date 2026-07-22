import 'package:dad_app/widgets/text.dart';
import 'package:flutter/material.dart';

import '../../styles/themes.dart';
import '../../utils/utils.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const SubHeader('About Us'),
        ),
        body: Container(
          color: backgroundColor,
          child: SizedBox(
              width: screenWidth(context),
              height: screenHeight(context),
              child: SingleChildScrollView(
                child: Padding(
                    padding: EdgeInsets.all(screenWidth(context) / 20),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              MyStuffLogo(),
                              RusmarkLogo(),
                            ],
                          ),
                          const SubHeader(
                            "\nWelcome to Rusmark – Inventing the Future\n\nOur Mission",
                          ),
                          const BodyText(
                            "Our mission is to empower individuals to manage their possessions efficiently "
                            "and bring peace of mind to their everyday lives. We believe that by combining cutting-edge "
                            "technology with user-friendly design, we can simplify the task of keeping track of your valuable items.",
                          ),
                          const SubHeader("\nThe MyStuff Service"),
                          const BodyText(
                              "MyStuff is more than just a tracking service; it's a companion on your journey to a more"
                              "organized and stress-free life. With MyStuff, you can effortlessly locate your items whether "
                              "it's your books, documents or anything else you consider valuable.We understand the importance of your "
                              "personal belongings, and we are committed to providing a service that meets your needs."),
                          const SubHeader("\nYour Privacy Matters"),
                          const BodyText(
                              "We understand the significance of privacy in the digital age. "
                              "That's why we prioritize the security and confidentiality of your information. "
                              "Our privacy policy, effective from December 1st, 2023, outlines how we collect, use, and "
                              "protect your data"),
                          const SubHeader("\nGet in Touch"),
                          const BodyText(
                              "We value your feedback and are always here to assist you. "
                              "If you have any questions, suggestions, or just want to say hello, don't "
                              "hesitate to reach out to us at rusmarkcompany@gmail.com.\n\n\n "
                              "Thank you for choosing MyStuff. We look forward to being part of your "
                              "journey to a more organized and connected life."),
                        ])),
              )),
        ));
  }
}
