import 'dart:math';
import 'package:flutter/material.dart';
import '../../common/admob.dart';
import '../../common/local_storage.dart';
import '../../common/secure_storage.dart';
import 'package:get/get.dart';
import 'dart:ui' as ui;
// base64库
import 'dart:convert' as convert;
import 'package:crypto/crypto.dart';

log(var content, {icon = 'info', time = false}) {
  assert((){
    if (true) {
      if (icon == 'ok') {
        icon = '✅';
      } else if (icon == 'error') {
        icon = '❌';
      } else if (icon == 'info') {
        icon = '💥';
      }
      debugPrint("${icon * 4}${time ? DateTime.now() : ''} $content ${icon * 4}");
    }
    return true;
  }());
}

class Tools {
  /// 时间差
  static timeHandler(int timestamp) {
    if(timestamp == 0){
      return 'await';
    }

    int length = timestamp.toString().length;
    DateTime old;
    if(length == 10){
      old = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    }else{
      old = DateTime.fromMillisecondsSinceEpoch(timestamp);
    }

    DateTime now = DateTime.now();
    Duration timeLag = now.difference(old); //时间戳进行比较
    int dayLag = timeLag.inDays;
    int hourLag = timeLag.inHours;
    int minLag = timeLag.inMinutes;
    int secLag = timeLag.inSeconds;


    if (dayLag > 365) {
      return '${dayLag~/365} year ago';
    } else if (dayLag > 30 && dayLag <= 365){
      return '${dayLag~/30} month ago';
    } else if (dayLag > 1 && dayLag <= 30){
      return '$dayLag day ago';
    } else if (hourLag < 24 && hourLag > 1) {
      return "$hourLag hours ago";
    } else if (minLag > 0 && minLag < 60) {
      return "$minLag minutes ago";
    } else if (secLag > 0 && secLag < 60) {
      return "$secLag seconds ago";
    } else {
      return "await";
    }
  }

  ///toast
  static toast(String message, {String type = 'success', int time = 3}) {
    MaterialColor background;
    String title;
    if (type == 'success') {
      background = Colors.green;
      title = '通知'.tr;
    } else if (type == 'error') {
      background = Colors.red;
      title = '错误'.tr;
    } else {
      background = Colors.grey;
      title = '通知'.tr;
    }
    Get.snackbar(
      title,
      message,
      duration: Duration(seconds: time),
      backgroundColor: background,
      colorText: Colors.white,
      borderRadius: 8.0,
    );
  }

  static MaterialColor createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }

/*
  * Base64加密
  */
  static String base64Encode(String data) {
    var content = convert.utf8.encode(data);
    var digest = convert.base64Encode(content);
    return digest;
  }

/*
  * Base64解密
  */
  static String base64Decode(String data) {
    List<int> bytes = convert.base64Decode(data);
    // 网上找的很多都是String.fromCharCodes，这个中文会乱码
    //String txt1 = String.fromCharCodes(bytes);
    String result = convert.utf8.decode(bytes);
    return result;
  }

  /// 生成MD5
  static String generateMd5(String input) {
    return md5.convert(convert.utf8.encode(input)).toString();
  }


  ///对远程获取的key，进行一些混淆处理
  String mixKey(String key) {
    key = key.replaceAll(" ", "");
    return key;
  }

  /// 获取到请求的
  /// md5(access_token + random_str + salt) + random_str_fake
  static Future<String> getRequestToken() async {
    String accessToken = await SecureStorage().read('at');
    String requestSalt = await SecureStorage().read('rk');
    return generateMd5(accessToken + generateRandom(length: 10));
  }

  ///生成随机字符串
  static String generateRandom({int length = 32}) {
    final _random = Random();
    const _availableChars = 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p9q7r8s9t0u1v2w3x4y5z';
    final randomString =
        List.generate(length, (index) => _availableChars[_random.nextInt(_availableChars.length)]).join();
    return randomString;
  }

  /// List<String>转List<int>
  static List<int> listStringTransitionInt(List<String> list) {
    List<int> intList = [];
    for (var value in list) {
      intList.add(int.parse(value));
    }
    return intList;
  }

  /// 根据下标判断需要插入几条广告
  static int indexComputeAd(int length, List<int> list) {
    //[1,4,9] 10
    int i = 0;
    for (var value in list) {
      if (value < length) {
        i++;
        continue;
      } else {
        break;
      }
    }
    return i;
  }

  /// 插入广告到列表
  static List insertNativeAd({required List dataList, required List<int> insertIndex}) {
    var admob = Admob();
    int length = dataList.length;
    int lengthIndex = Tools.indexComputeAd(length, insertIndex);

    /// 其他通用情况
    for (var i = 0; i < length + lengthIndex; i++) {
      if (insertIndex.contains(i)) {
        if (admob.preloadNativeAd.isNotEmpty) {
          //log('i = $i 符合要求，插入广告');
          String adKey = admob.preloadNativeAd.keys.toList()[0];
          dataList.insert(i, admob.preloadNativeAd[adKey]);
          admob.preloadNativeAd.remove(adKey);
        } else {
          admob.getNativeAd('phone_list_native', number: 4);
          //log('加载广告缓存为空，存在正在加载的广告 = ${admob.preloadNativeAdWait.length}');
          /*if(admob.preloadNativeAdWait.length == 0){
            log("Phone原生广告缓存不存在，预加载4条");
            admob.getNativeAd(number: 4);
          }*/
          //dataList.insert(i, admob.getNativeAd(isPreload: false));
          //log("实时插入原生广告");
        }
      }
    }
    return dataList;
  }

  /// 邮箱判断
  static bool isEmail(String input) {
    String regexEmail = "^\\w+([-+.]\\w+)*@\\w+([-.]\\w+)*\\.\\w+([-.]\\w+)*\$";
    if (input.isEmpty) return false;
    return RegExp(regexEmail).hasMatch(input);
  }

  /// 获取当前时间年月日
  static String getYmd({String ymd = 'full', int timestamp = 0, String line = ''}) {
    DateTime dates;

    if (timestamp > 0) {
      var newTime = timestamp.toString();
      if (newTime.length == 10) {
        newTime = newTime + '000';
        dates = DateTime.fromMillisecondsSinceEpoch(int.parse(newTime));
      } else {
        dates = DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } else {
      dates = DateTime.now();
    }

    /// 日期没有间隔
    if (line == '') {
      if (ymd == 'ymdh') {
        return "${dates.year.toString()}${dates.month.toString().padLeft(2, '0')}${dates.day.toString().padLeft(2, '0')}"
            "${dates.hour.toString().padLeft(2, '0')}";
      }

      if (ymd == 'ymdhm') {
        return "${dates.year.toString()}${dates.month.toString().padLeft(2, '0')}${dates.day.toString().padLeft(2, '0')}"
            "${dates.hour.toString().padLeft(2, '0')}${dates.minute.toString().padLeft(2, '0')}";
      }

      return "${dates.year.toString()}${dates.month.toString().padLeft(2, '0')}${dates.day.toString().padLeft(2, '0')}"
          "${dates.hour.toString().padLeft(2, '0')}${dates.minute.toString().padLeft(2, '0')}${dates.second.toString().padLeft(2, '0')}";
    } else {
      /// 日期有间隔
      return "${dates.year.toString()}$line${dates.month.toString().padLeft(2, '0')}$line${dates.day.toString().padLeft(2, '0')}"
          " ${dates.hour.toString().padLeft(2, '0')}:${dates.minute.toString().padLeft(2, '0')}:${dates.second.toString().padLeft(2, '0')}";
    }
  }

  /// 获取当前语言包给Api接口端使用
  static String getCurrentLanguage() {
    var language = LocalStorage().getJSON('language');
    if (language == null) {
      return ui.window.locale.languageCode;
    }
    return language['languageCode'];
  }

  /// 给一个百分比，按概率是否选中
  static bool isSelect(int percentage) {
    int num = Random().nextInt(100);
    if (num > percentage) {
      return false;
    } else {
      return true;
    }
  }

  // 广告显示后方法
  static void onAdShowFun(){
    if(LocalStorage().getBool('isAd') == false){
      LocalStorage().remove('AdShowed');
      LocalStorage().remove('requestNumber');
      LocalStorage().setBool('isAd', true);
      log('广告屏蔽解除');
    }else{
      LocalStorage().setIncr('AdShowed');
      log('AdShowed +1');
    }
  }

}
