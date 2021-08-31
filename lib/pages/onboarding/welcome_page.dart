import 'package:get/get.dart';
import 'package:roomies/pages/onboarding/phone_number_page.dart';
import 'package:roomies/util/utils.dart';
import 'package:roomies/widgets/round_button.dart';
import 'package:roomies/util/style.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {


  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    Data.addInterests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        padding: const EdgeInsets.only(
          left: 50,
          right: 50,
          bottom: 60,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            buildTitle(),
            SizedBox(
              height: 40,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Roomy hold professional, social and political talks with Roomy :)',
            style: TextStyle(
              height: 1.8,
              fontSize: 15,
            ),
          ),
          SizedBox(
            height: 40,
          ),
          Text(
            'Roomy doesnt discriminate, join anywhere you are, hold any kind of talk shows, invite your friends and much much more :)',
            style: TextStyle(
              height: 1.8,
              fontSize: 15,
            ),
          ),
          SizedBox(
            height: 40,
          ),
          Text(
            '🎙 Patrick, Reginah & the Roomy team',
            style: TextStyle(
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBottom(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CustomButton(
          color: Style.AccentGreen,
          onPressed: () {
            Get.to(() => PhoneScreen());
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Get started',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                Icon(
                  Icons.arrow_right_alt,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 20,
        ),
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   children: [
        //     Text(
        //       'Have an invite text?',
        //       style: TextStyle(
        //         color: Style.AccentBlue,
        //       ),
        //     ),
        //     SizedBox(
        //       width: 5,
        //     ),
        //     Text(
        //       'Sign in',
        //       style: TextStyle(
        //         color: Style.AccentBlue,
        //         fontWeight: FontWeight.bold,
        //       ),
        //     ),
        //     Icon(
        //       Icons.arrow_right_alt,
        //       color: Style.AccentBlue,
        //     ),
        //   ],
        // ),
      ],
    );
  }
}
