import 'package:get/get.dart';
import 'package:richtalk/pages/onboarding/phone_number_page.dart';
import 'package:richtalk/util/utils.dart';
import 'package:richtalk/widgets/round_button.dart';
import 'package:richtalk/util/style.dart';
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
      //appBar: AppBar(),
      body: Container(
        //padding: const EdgeInsets.all(20),
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // buildTitle(),
            Text(
              'Rt.',
              style: TextStyle(
                fontSize: 80,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w800,
                color: Style.pinkAccent,
              ),
            ),
            Text(
              'Welcome to Rich Talk',
              style: TextStyle(
                  fontSize: 28,
                  fontFamily: 'Roboto-Light'
              ),
            ),
            Text(
              'Your Network is your Net Worth',
              style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Roboto'
              ),
            ),
            SizedBox(
              height: 40,
            ),
            // Expanded(
            //   child: buildContents(),
            // ),
            buildBottom(context),

          ],
        ),
      ),
    );
  }

  Widget buildTitle() {
    return Text(
      '🎉 Rt.',
      style: TextStyle(
        fontSize: 25,
        fontFamily: 'Roboto-bold',
        fontWeight: FontWeight.w800,
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
          color: Style.pinkAccent,
          onPressed: () {
            Get.to(() => PhoneScreen());
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 5),
            width: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Get started',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
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
        //         color: Style.pinkAccent,
        //       ),
        //     ),
        //     SizedBox(
        //       width: 5,
        //     ),
        //     Text(
        //       'Sign in',
        //       style: TextStyle(
        //         color: Style.pinkAccent,
        //         fontWeight: FontWeight.bold,
        //       ),
        //     ),
        //     Icon(
        //       Icons.arrow_right_alt,
        //       color: Style.pinkAccent,
        //     ),
        //   ],
        // ),
      ],
    );
  }
}
