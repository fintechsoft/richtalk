

import 'package:roomies/twilio/model/email_channel_configuration.dart';
import 'package:roomies/twilio/model/twilio_reponse.dart';

abstract class TwilioVerifyRepository {
  Future<TwilioResponse> sendSmsCode(String phone);
  Future<TwilioResponse> verifySmsCode(String phone, String code);
  Future<TwilioResponse> sendEmailCode(String email,{EmailChannelConfiguration channelConfiguration});
  Future<TwilioResponse> verifyEmailCode(String email, String code);
}