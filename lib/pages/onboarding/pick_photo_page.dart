import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:roomies/controllers/controllers.dart';
import 'package:roomies/services/database.dart';
import 'package:roomies/widgets/round_button.dart';
import 'package:roomies/util/style.dart';
import 'package:roomies/pages/home/home_page.dart';
import 'package:roomies/widgets/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class PickPhotoPage extends StatefulWidget {
  @override
  _PickPhotoPageState createState() => _PickPhotoPageState();
}

class _PickPhotoPageState extends State<PickPhotoPage> {
  final picker = ImagePicker();
  bool loading = false;
  File _imageFile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: loading == true ? loadingWidget() :Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.only(
            top: 30,
            bottom: 60,
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(horizontal: 15),
                child: InkWell(
                  onTap: () async {
                    setState(() {
                      loading = true;
                    });
                      Get.find<OnboardingController>().imageFile = null;
                        await Database().createUserInfo(FirebaseAuth.instance.currentUser.uid);
                      setState(() {
                        loading = false;
                      });
                  },
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text("Skip", style: TextStyle(fontSize: 21),),
                  ),
                ),
              ),
              buildTitle(),
              Spacer(
                flex: 1,
              ),
              buildContents(),
              Spacer(
                flex: 3,
              ),
              buildBottom(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildActionButton(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: GestureDetector(
        onTap: () {
          Get.to(() => HomePage());
        },
        child: Text(
          'Skip',
          style: TextStyle(
            color: Style.DarkBrown,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget buildTitle() {
    return Text(
      'Add your photo?',
      style: TextStyle(
        fontSize: 25,
      ),
    );
  }
  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: false,
          title: const Text('Add a profile photo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10,),
              InkWell(
                onTap: (){
                  Navigator.pop(context);
                  _getFromGallery();
                },
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text("Choose from galley"),
                ),
              ),
              SizedBox(height: 20,),
              InkWell(
                onTap: (){
                  Navigator.pop(context);
                  _getFromCamera();
                },
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text("Take photo"),
                ),
              )
            ],
          ),
        );
      },
    );
  }
  Widget buildContents() {
    return Container(
      child: GestureDetector(
        onTap: () {
          // _getFromGallery();
          _showMyDialog();

        },
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(80),
          ),
          child: _imageFile !=null ? Container(
                child: ClipOval(
                  child: Image.file(
                    _imageFile,
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ) : Icon(
            Icons.add_photo_alternate_outlined,
            size: 100,
            color: Style.AccentBlue,
          ),
        ),
      ),
    );
  }

  Widget buildBottom(BuildContext context) {
    return CustomButton(
      color: Style.AccentBlue,
      minimumWidth: 230,
      disabledColor: Style.AccentBlue.withOpacity(0.3),
      onPressed: _imageFile == null ? null : () async{
        setState(() {
          loading = true;
        });
        await Database().createUserInfo(FirebaseAuth.instance.currentUser.uid);
        setState(() {
          loading = false;
        });
      },
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
            Icon(
              Icons.arrow_right_alt,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  _getFromGallery() async {
    PickedFile pickedFile = await picker.getImage(
      source: ImageSource.gallery,
    );
    _cropImage(pickedFile.path);
  }
  _getFromCamera() async {
    PickedFile pickedFile = await picker.getImage(
      source: ImageSource.camera,
    );
    _cropImage(pickedFile.path);
  }

  _cropImage(filePath) async {
    File croppedImage = await ImageCropper.cropImage(
        sourcePath: filePath,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
        aspectRatioPresets: [CropAspectRatioPreset.square],
        compressQuality: 70,
        compressFormat: ImageCompressFormat.jpg,
        iosUiSettings: IOSUiSettings(
          minimumAspectRatio: 1.0,
          rotateClockwiseButtonHidden: false,
          rotateButtonsHidden: false,
        )
    );
    if (croppedImage != null) {
      _imageFile = croppedImage;
      Get.find<OnboardingController>().imageFile = _imageFile;
      setState(() {});
    }
  }
}
