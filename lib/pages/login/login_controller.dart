import 'package:flutter/cupertino.dart';
import '../../common/auth.dart';
import '../../common/secure_storage.dart';
import 'package:get/get.dart';
import '../../utils/tools.dart';

class LoginController extends GetxController{
  final String title = '登陆'.tr;
  RxBool passwordVisible = RxBool(true);
  RxBool isChecked = RxBool(false);
  RxString username = RxString('');
  RxString password = RxString('');
  late TextEditingController emailTextForm;
  late TextEditingController passwordTextForm;

  @override
  void onReady() {
    log('LoginController onReady');
    super.onReady();
    SecureStorage().read('username').then((value){
      if(value != null){
        username.value = value;
        isChecked.value = true;
      }
    });
    SecureStorage().read('password').then((value){
      if(value != null){
        password.value = value;
      }
    });
  }

  @override
  void onClose() {
    super.onClose();
    log('Login onClose');
    emailTextForm.dispose();
    passwordTextForm.dispose();
  }


  //切换密码查看
  void togglePassword(){
    if(passwordVisible.value == false){
      passwordVisible.value = true;
    }else{
      passwordVisible.value = false;
    }
  }

  //切换密码查看
  void toggleIsChecked(){
    if(isChecked.value == false){
      isChecked.value = true;
    }else{
      isChecked.value = false;
    }
  }

  //登陆
  login(String username, String password) async{
    bool isLogin = await Auth().login(username, password);
    log(isLogin);
    if (isLogin) {
      //判断是否保存密码
      if(isChecked.value == true){
        SecureStorage().write('username', username);
        SecureStorage().write('password', password);
      }else{
        SecureStorage().del(key: 'username');
        SecureStorage().del(key: 'password');
      }
      //登陆成功，跳转My页面
      Get.back(result: 'LoginSuccess');
    }
  }

  Future<String?> getUsername() async {
    await SecureStorage().read('username').then((value) => value);
    return null;
  }

}