import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../utils/tools.dart';

class RegisterController extends GetxController {
  final String title = '注册'.tr;
  RxBool passwordVisible = RxBool(false);
  RxBool isChecked = RxBool(false);
  final emailTextForm = TextEditingController();
  final codeTextForm = TextEditingController();
  final passwordTextForm = TextEditingController();
  final password2TextForm = TextEditingController();
  var isSendCode = false.obs;
  var countDownTitle = '发送验证码'.tr.obs;
  //倒计时起始时间
  int _countTime = 30;
  //计时器
  Timer? _timer;

  @override
  void onClose() {
    super.onClose();
    emailTextForm.dispose();
    passwordTextForm.dispose();
    password2TextForm.dispose();
    codeTextForm.dispose();
    _timer?.cancel();
  }

  //切换密码查看
  void togglePassword() {
    if (passwordVisible.value == false) {
      passwordVisible.value = true;
    } else {
      passwordVisible.value = false;
    }
  }

  //切换密码查看
  void toggleIsChecked() {
    if (isChecked.value == false) {
      isChecked.value = true;
    } else {
      isChecked.value = false;
    }
  }

  //倒计时功能
  void startCountDownTime() {
    // 给邮箱发送邮箱
    String email = emailTextForm.text.trim();
    log(email);
    int defaultTime = 30;
    if (_countTime == defaultTime) {
      //计时器实例
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_countTime < 2) {
          countDownTitle.value = '发送验证码'.tr;
          _timer?.cancel();
          _countTime = defaultTime;
        } else {
          _countTime--;
          countDownTitle.value = '$_countTime' + 's' + '秒后重新获取'.tr;
        }
      });
    }
  }
}
