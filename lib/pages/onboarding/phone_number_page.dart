import 'package:roomies/controllers/controllers.dart';
import 'package:roomies/util/configs.dart';
import 'package:roomies/models/models.dart';
import 'package:roomies/twilio/api.dart';
import 'package:roomies/widgets/round_button.dart';
import 'package:roomies/widgets/widgets.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:roomies/util/style.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'sms_screen.dart';

class PhoneScreen extends StatefulWidget {
  @override
  _PhoneScreenState createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _phoneNumberController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Function onSignUpButtonClick;
  UserModel user = Get.put(OnboardingController()).onboardingUser;
  String verificationId;
  String countrycode;
  String countryname;
  String error = "";
  bool loading = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _twilioPhoneVerify = new TwilioPhoneVerify(
        accountSid: accountSid, // replace with Account SID
        authToken: authToken, // replace with Auth Token
        serviceSid: serviceSid // replace with Service SIDe with Service SID
        );
  }

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
            SizedBox(
              height: 10,
            ),
            Text(
              error,
              style: TextStyle(color: Colors.red),
            ),
            Spacer(),
            buildBottom(),
          ],
        ),
      ),
    );
  }

  Widget buildTitle() {
    return Text(
      'Enter your phone #',
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
      child: Row(
        children: [
          CountryCodePicker(
            initialSelection: 'KE',
            showCountryOnly: false,
            alignLeft: false,
            onInit: (code) {
              countrycode = code.dialCode;
              countryname = code.name;
              user.countrycode = code.dialCode;
              user.countryname = code.name;

              print("on init ${code.name} ${code.dialCode} ${code.name}");
            },
            padding: const EdgeInsets.all(8),
            onChanged: (code) {
              countrycode = code.dialCode;
              countryname = code.name;
              user.countrycode = code.dialCode;
              user.countryname = code.name;
            },
            textStyle: TextStyle(
              fontSize: 20,
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: TextFormField(
                onChanged: (value) {
                  _formKey.currentState.validate();
                },
                validator: (value) {
                  if (value.isEmpty) {
                    setState(() {
                      onSignUpButtonClick = null;
                    });
                  } else {
                    setState(() {
                      onSignUpButtonClick = signUp;
                    });
                  }
                  return null;
                },
                controller: _phoneNumberController,
                autocorrect: false,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'Phone Number',
                  hintStyle: TextStyle(
                    fontSize: 20,
                  ),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                ),
                keyboardType: TextInputType.numberWithOptions(
                    signed: true, decimal: true),
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBottom() {
    return Column(
      children: [
        Text(
          'By entering your number, you\'re agreeing to our\nTerms or Services and Privacy Policy. Thanks!',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
        SizedBox(
          height: 30,
        ),
        CustomButton(
          color: Style.AccentBlue,
          minimumWidth: 230,
          disabledColor: Style.AccentBlue.withOpacity(0.3),
          onPressed: onSignUpButtonClick,
          child: Container(
            width: 100,
            child: loading == true
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : Row(
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
        ),
      ],
    );
  }

  Future<void> verifyPhone(phoneNumber) async {
    final PhoneVerificationCompleted verified = (AuthCredential authResult) {

    };

    final PhoneVerificationFailed verificationfailed = (authException) {
      if (APP_ENV_DEV == true) {
        Get.to(() => SmsScreen(
            phone: user.countrycode + "" + _phoneNumberController.text, logintype: "test",));

      }else{
        setState(() {
          loading = false;
          error = "Technical error happened";
        });
        print('ttt ${authException.toString()}');

      }
    };

    final PhoneCodeSent smsSent = (String verId, [int forceResend]) {
      this.verificationId = verId;
      Get.to(() => SmsScreen(
          verificationId: verId,
          phone: user.countrycode + "" + _phoneNumberController.text,
          logintype: logintype));
      setState(() {
        loading = false;
      });
    };

    final PhoneCodeAutoRetrievalTimeout autoTimeout = (String verId) {
      this.verificationId = verId;
    };

    await FirebaseAuth.instance.verifyPhoneNumber(

        /// Make sure to prefix with your country code
        phoneNumber: phoneNumber,

        ///No duplicated SMS will be sent out upon re-entry (before timeout).
        timeout: const Duration(seconds: 5),

        /// If the SIM (with phoneNumber) is in the current device this function is called.
        /// This function gives `AuthCredential`. Moreover `login` function can be called from this callback
        /// When this function is called there is no need to enter the OTP, you can click on Login button to sigin directly as the device is now verified
        verificationCompleted: verified,

        /// Called when the verification is failed
        verificationFailed: verificationfailed,

        /// This is called after the OTP is sent. Gives a `verificationId` and `code`
        codeSent: smsSent,

        /// After automatic code retrival `tmeout` this function is called
        codeAutoRetrievalTimeout: autoTimeout);
  }

  TwilioPhoneVerify _twilioPhoneVerify;
  String logintype = "";

  signUp() async {
    if (_phoneNumberController.text.isEmpty) {
      setState(() {
        error = "Enter Phone Number";
      });
    } else {
        setState(() {
          loading = true;
          error = "";
        });

        //USE EITHER FIREBASE OR TWILIO FOR AUTH (-ONLY ON DEVELOPMENT MODE-)
        if(APP_ENV_DEV){
          var twilioResponse = await _twilioPhoneVerify.sendSmsCode(user.countrycode + "" + _phoneNumberController.text);
          if (twilioResponse.successful) {
            logintype = "twilio";
            //code sent
            setState(() {
              loading = false;
            });
            Get.to(() => SmsScreen(
              phone: user.countrycode + "" + _phoneNumberController.text, logintype: logintype,));
          } else {
            print(twilioResponse.statusCode);
            print(twilioResponse.errorMessage);
            logintype = "firebase";
            verifyPhone(user.countrycode + "" + _phoneNumberController.text);
          }
        }else {
          //USE TWILIO FOR AUTHNTICATIONS
          if (ENABLE_TWILIO_AUTH) {
            var twilioResponse = await _twilioPhoneVerify
                .sendSmsCode(
                user.countrycode + "" + _phoneNumberController.text);

            if (twilioResponse.successful) {
              logintype = "twilio";
              //code sent
              setState(() {
                loading = false;
              });
              Get.to(() =>
                  SmsScreen(
                    phone: user.countrycode + "" + _phoneNumberController.text,
                    logintype: logintype,));
            }
          }
          //USE FIREBASE FOR AUTHNTICATIONS
          if (ENABLE_FIREBASE_AUTH) {
            verifyPhone(user.countrycode + "" + _phoneNumberController.text);
          }
        }

      }

  }
}
