import 'package:richtalk/controllers/controllers.dart';
import 'package:richtalk/services/database.dart';
import 'package:richtalk/widgets/round_button.dart';
import 'package:richtalk/util/style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:richtalk/widgets/widgets.dart';

import 'pick_photo_page.dart';

class UsernamePage extends StatefulWidget {
  @override
  _UsernamePageState createState() => _UsernamePageState();
}

class _UsernamePageState extends State<UsernamePage> {
  final _userNameController = TextEditingController();
  final _userNameformKey = GlobalKey<FormState>();
  bool loading = false;
  Function onNextButtonClick;

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
            buildForm(),
            Spacer(),
            buildBottom(),
          ],
        ),
      ),
    );
  }

  Widget buildTitle() {
    return Text(
      'Pick a username',
      style: TextStyle(
        fontSize: 25,
      ),
    );
  }

  Widget buildForm() {
    return Container(
      width: 330,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Form(
        key: _userNameformKey,
        child: TextFormField(
          textAlign: TextAlign.center,
          onChanged: (value) {
            _userNameformKey.currentState.validate();

          },
          validator: (value) {
            if (value.isEmpty) {
              setState(() {
                onNextButtonClick = null;
              });
            } else {
              setState(() {
                onNextButtonClick = next;
              });
            }
            return null;
          },
          controller: _userNameController,
          autocorrect: false,
          autofocus: false,
          decoration: InputDecoration(
            hintText: '@username',
            hintStyle: TextStyle(
              fontSize: 20,
            ),
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
          ),
          keyboardType: TextInputType.text,
          style: TextStyle(
            fontSize: 20,
            color: Colors.black,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget buildBottom() {
    return loading == true ? Center(
      child: CircularProgressIndicator(),
    ) : CustomButton(
      color: Style.pinkAccent,
      disabledColor: Style.pinkAccent.withOpacity(0.3),
      onPressed: onNextButtonClick,
      child: Container(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Next',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  next() {
    setState(() {
      loading = true;
    });
    print(_userNameController.text);
    Database.checkUsername(_userNameController.text).then((value){
      if(value == 0){
        setState(() {
          onNextButtonClick = next;
          Get.find<OnboardingController>().username = _userNameController.text;
          Get.to(() => PickPhotoPage());
        });
      }else{
        topTrayPopup("Username is already taken");
      }

      setState(() {
        loading = false;
      });
    });

  }
}