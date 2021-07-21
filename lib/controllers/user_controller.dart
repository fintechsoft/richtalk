import 'package:get/get.dart';
import 'package:roomies/models/models.dart';
/*
  type : Class
  packages used: Getx
  function: this is the controller class that listens to user object changes
 */
class UserController extends GetxController {
  Rx<UserModel> _userModel = UserModel().obs;

  UserModel get user => _userModel.value;

  set user(UserModel value) => this._userModel.value = value;
}