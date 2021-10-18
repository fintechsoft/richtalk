import 'package:richtalk/services/authenticate.dart';
import 'package:richtalk/twilio/api.dart';
import 'package:richtalk/twilio/model/verification.dart';
import 'package:richtalk/util/configs.dart';
import 'package:richtalk/util/utils.dart';
import 'package:richtalk/widgets/round_button.dart';
import 'package:flutter/material.dart';

class SmsScreen extends StatefulWidget {
  final String verificationId;
  final String phone;
  final String logintype;

  const SmsScreen({Key key, this.verificationId, this.phone, this.logintype})
      : super(key: key);

  @override
  _SmsScreenState createState() => _SmsScreenState();
}

class _SmsScreenState extends State<SmsScreen> {
  final _smsController = TextEditingController();
  bool loading = false;
  String errortxt = "";

  TwilioPhoneVerify _twilioPhoneVerify;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (APP_ENV_DEV == true && widget.logintype == "test") {
      _smsController.text = "123456";
      setState(() {});
    }

    _twilioPhoneVerify = new TwilioPhoneVerify(
        accountSid: accountSid, // replace with Account SID
        authToken: authToken, // replace with Auth Token
        serviceSid: serviceSid // replace with Service SID
    );
  }

  @override
  Widget build(BuildContext context) {
    print("code" + _smsController.text);
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.only(top: 30, bottom: 10),
        child: Column(
          children: [
            title(),
            SizedBox(height: 50),
            form(),
            //Spacer(),
            SizedBox(height: 20),
            loading == true
                ? Center(
              child: CircularProgressIndicator(),
            )
                : bottom(),
          ],
        ),
      ),
    );
  }

  Widget title() {
    return Padding(
      padding: const EdgeInsets.only(left: 80.0, right: 80.0),
      child: Text(
        'Enter the code we just texted you',
        style: TextStyle(fontSize: 18),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget form() {
    return Column(
      children: [
        Container(
          width: 330,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Form(
            child: TextFormField(
              textAlign: TextAlign.center,
              controller: _smsController,
              enabled: APP_ENV_DEV == true && widget.logintype == "test"
                  ? false
                  : true,
              autocorrect: false,
              autofocus: APP_ENV_DEV == true && widget.logintype == "test",
              decoration: InputDecoration(
                hintText: '••••••',
                hintStyle: TextStyle(
                  fontSize: 20,
                ),
                border: InputBorder.none,
              ),
              keyboardType: TextInputType.number,
              style: TextStyle(
                  fontSize: 25,
                  color: Colors.black,
                  fontWeight: FontWeight.w400),
            ),
          ),
        ),
        SizedBox(height: 15.0),
        if (errortxt.isNotEmpty)
          Text(
            errortxt,
            style: TextStyle(color: Style.pinkAccent),
          ),
        Text(
          'Didnt receive it? Tap to resend.',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget bottom() {
    return Column(
      children: [
        SizedBox(height: 10),
        CustomButton(
          color: Style.pinkAccent,
          disabledColor: Style.pinkAccent.withOpacity(0.3),
          onPressed: () async {
            errortxt = "";
            setState(() {
              loading = true;
            });
            if (APP_ENV_DEV) {
              await AuthService().signInWithEmail(widget.phone).then((value) {
                print("response from service " + value.toString());
                setState(() {
                  loading = false;
                });
              });
            } else {
              // print("widget.logintype"+widget.logintype);
              if (ENABLE_TWILIO_AUTH) {
                var twilioResponse = await _twilioPhoneVerify.verifySmsCode(
                    phone: widget.phone, code: _smsController.text);

                if (twilioResponse.successful) {
                  if (twilioResponse.verification.status ==
                      VerificationStatus.approved) {
                    //print('Phone number is approved');
                    await AuthService()
                        .signInWithEmail(widget.phone)
                        .then((value) {
                      print("response from service " + value.toString());
                      setState(() {
                        loading = false;
                      });
                    });
                  } else {
                    errortxt = "Otp is not valid";
                    setState(() {
                      loading = false;
                    });
                    //print('Invalid code');
                  }
                } else {
                  //print(twilioResponse.errorMessage);
                }
              } else if (ENABLE_FIREBASE_AUTH) {
                await AuthService()
                    .signInWithOTP(widget.verificationId, _smsController.text,
                    widget.phone)
                    .then((value) {
                  print(value);
                  if (value == "null") {
                    errortxt = "Otp is not valid";
                    setState(() {
                      loading = false;
                    });
                  } else {
                    setState(() {
                      loading = false;
                    });
                  }
                });
              }
            }
          },
          child: Container(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Verify',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
