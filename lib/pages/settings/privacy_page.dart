import 'package:dad_app/widgets/text.dart';
import 'package:flutter/material.dart';

import '../../styles/themes.dart';
import '../../utils/utils.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const SubHeader('Privacy Policy'),
        ),
        body: Container(
          color: backgroundColor,
          child: SizedBox(
              width: screenWidth(context),
              height: screenHeight(context),
              child: SingleChildScrollView(
                child: Padding(
                    padding: EdgeInsets.all(screenWidth(context) / 20),
                    child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SubHeader(
                              "Privacy Policy for Rusmark - MyStuff Service\n "
                              "\nEffective Date: 1st January 2024 "),
                          BodyText(
                              "\nThank you for choosing Rusmark and using our MyStuff service. At Rusmark, we are  "
                              "committed to safeguarding your privacy. This Privacy Policy explains how we collect, use,  "
                              "disclose, and protect your information when you use our MyStuff service. Please take a  "
                              "moment to review this policy to understand how your personal information is treated.  "),
                          Header('\nInformation We Collect'),
                          SubHeader("\nAccount Information "),
                          BodyText(
                              "When you create a MyStuff account, we collect your email address to uniquely identify  "
                              "your account. "),
                          SubHeader("\nLocation Information "),
                          BodyText(
                            "MyStuff is designed to track the physical location of items. To provide "
                            "this service, we may collect and store location information of your tracked items. ",
                          ),
                          SubHeader("\nUsage Data "),
                          BodyText(
                              "We collect data about how you interact with our service, including the features you use,  "
                              "the items you track, and the frequency of your interactions. "),
                          Header('\nHow We Use Your Information'),
                          SubHeader("\nProviding and Improving the Service "),
                          BodyText(
                            "We use your information to operate, maintain, and enhance the MyStuff service. This "
                            "includes providing customer support, personalized features, and continually  "
                            "improving the user experience. ",
                          ),
                          SubHeader("\nCommunication "),
                          BodyText(
                              "We may use your email address to communicate important updates, notifications, and  "
                              "information about your account and the MyStuff service. "),
                          SubHeader("\nAggregated Data "),
                          BodyText(
                            "We may aggregate anonymize data to analyze usage patterns, troubleshoot issues, and  "
                            "improve our service. This aggregated data does not identify individual users. ",
                          ),
                          Header('\nInformation Sharing'),
                          SubHeader("\nThird-Party Service Providers "),
                          BodyText(
                            "We may engage third-party service providers to assist us in providing and maintaining the MyStuff service.  "
                            "These providers have limited access to your information and are bound by confidentiality agreements. ",
                          ),
                          SubHeader("\nLegal Compliance "),
                          BodyText(
                              "We may disclose your information if required to do so by law or in response to valid  "
                              "requests by public authorities. "),
                          Header("\nSecurity "),
                          BodyText(
                            "We take reasonable measures to protect your information from unauthorized access, disclosure, alteration, and destruction. However, no data transmission  "
                            "over the internet or electronic storage method is completely secure, and we cannot guarantee absolute security. ",
                          ),
                          Header("\nYour Choices "),
                          BodyText(
                              "You can review, update, or delete your account information by accessing your  "
                              "MyStuff account settings. You may also contact us at rusmarkcompany@gmail.com  "
                              "for assistance. "),
                          Header("\nChanges to this Privacy Policy "),
                          BodyText(
                              "We reserve the right to update this Privacy Policy to reflect changes in our practices  "
                              "and services. We will notify you of any material changes by email or by prominently  "
                              "posting a notice on our website. "),
                          Header("\nContact us "),
                          BodyText(
                              "If you have any questions, concerns, or requests regarding this Privacy Policy,  "
                              "please contact us at rusmarkcompany@gmail.com.\n\nBy using the MyStuff service,  "
                              "you agree to the terms outlined in this Privacy Policy.\n\nLast Updated: 1st December "
                              " 2023 ")
                        ])),
              )),
        ));
  }
}
