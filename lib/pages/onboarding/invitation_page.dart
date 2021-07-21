import 'package:get/get.dart';
import 'package:roomies/widgets/round_button.dart';
import 'package:roomies/widgets/round_image.dart';
import 'package:roomies/util/style.dart';
import 'package:flutter/material.dart';

import 'full_name_page.dart';

class InvitationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.only(
          top: 30,
          bottom: 60,
        ),
        child: Column(
          children: [
            buildTitle(),
            SizedBox(
              height: 50,
            ),
            Expanded(
              child: buildContents(),
            ),
            buildBottom(context),
          ],
        ),
      ),
    );
  }

  Widget buildTitle() {
    return Text(
      '🎉 Welcome to Roomy!',
      style: TextStyle(
        fontSize: 25,
      ),
    );
  }

  Widget buildContents() {
    return SingleChildScrollView(
      child: Column(
        children: [
          RoundImage(
            path: 'assets/images/avatar.png',
            width: 150,
            height: 150,
            borderRadius: 80,
          ),
        ],
      ),
    );
  }

  Widget buildBottom(BuildContext context) {
    return Column(
      children: [
        // Text(
        //   'Let\'s set up your profile?',
        //   style: TextStyle(
        //     fontSize: 20,
        //     fontWeight: FontWeight.w500,
        //   ),
        // ),
        // SizedBox(
        //   height: 30,
        // ),
        CustomButton(
          onPressed: () =>Get.to(() => FullNamePage()),
          minimumWidth: 230,
          color: Style.AccentBlue,
          text: 'Continue',
        ),
        SizedBox(
          height: 20,
        ),
      ],
    );
  }
}
