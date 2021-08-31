

import 'package:roomies/twilio/model/verification.dart';

String stringFromEnum(val) => val.toString().split('.').last;

VerificationStatus statusFromString(String status) =>
    VerificationStatus.values.firstWhere((e) => stringFromEnum(e) == status);
