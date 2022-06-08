import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../utils/config.dart';

class Loading {
  static Loading? _instance;

  factory Loading() {
    _instance ??= Loading._config();
    return _instance!;
  }

  Loading._config();

  static show({String? title}){
    EasyLoading.instance
      ..indicatorColor = Colors.white
      ..textColor = Colors.white
      ..indicatorType = EasyLoadingIndicatorType.fadingCircle
      ..loadingStyle = EasyLoadingStyle.custom
      ..backgroundColor = const Color(PRIMARYCOLOR)
      ..userInteractions = true
      ..dismissOnTap = false;
    if(title != null){
      EasyLoading.show(status: title + '...');
    }else{
      EasyLoading.show();
    }

  }

  static hide(){
    EasyLoading.dismiss();
  }
}
