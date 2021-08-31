
import 'verification.dart';

class TwilioResponse{
  String errorMessage;
  int statusCode;
  bool successful;
  Verification verification;
  TwilioResponse({this.statusCode,this.errorMessage,this.verification,this.successful});
}