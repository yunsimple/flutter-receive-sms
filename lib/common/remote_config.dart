import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../utils/config.dart';
import '../utils/tools.dart';
import 'package:get/get.dart';

class RemoteConfigApi {
  static RemoteConfigApi? _instance;
  FirebaseRemoteConfig config = FirebaseRemoteConfig.instance;

  factory RemoteConfigApi() {
    _instance ??= RemoteConfigApi._config();
    return _instance!;
  }

  RemoteConfigApi._config();

  //初始化
  Future<void> init() async {
    //log('RemoteConfig init');
    //设置超时时间
    await config.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: FIREBASE_TIMEOUT),

      /// todo 生产模式，这里的值需要更改
      minimumFetchInterval: const Duration(hours: 6),
    ));

    // 设置默认参数
    /// 上线前要设置默认值
    await config.setDefaults(const {
      /// todo rk需不需要默认
      'baseUrl': 'https://api.receivesms.top/',
      'adSwitch':
          '{"adSwitchBanner":true,"adSwitchInterstitial":true,"adSwitchNative":true,"adSwitchOpenApp":true,"adSwitchRewarded":true,"nativeSize":"random"}',
      'noticeSwitch': true,
      'adRewardedCoins': 10,
      //'rk': 'SsCF5poAfNB4frq5',
      'adPopup':
          '{"isShow":true,"showMode":"random","percentage":50,"ad":["rewarded","interstitial"],"rewardedPercentage":50,"interstitialPercentage":50}',
      'adblock': '{"adPercentage":20,"day":7,"request":100}',
      'message': '{"isLoad":false,"adMessageNativeIndex":"1,3,7,15","adPhoneNativeSize":"random"}',
      'phone': '{"adPhoneNativeIndex":"1,4,9","adPhoneNativeSize":"random"}',
    });

    //从服务器获取新数据并激活值
    if (config.lastFetchStatus == RemoteConfigFetchStatus.noFetchYet || config.lastFetchStatus == RemoteConfigFetchStatus.failure) {
      // 第一次启动时
      await fetchAndActivate();
    } else {
      // 第N次启动时
      await config
          .activate();
          //.then((value) => log("Remote Config activate激活完成，可以使用", icon: 'ok', time: true))
          //.catchError((onError) => log("Remote Config激活失败 = $onError", icon: 'error'));
      // 重新拉取最新值，供下次使用
      fetch();
    }
  }

  Future<bool> fetchAndActivate({bool minimumFetchInterval = false}) async {
    if (minimumFetchInterval) {
      //设置超时时间
      await config.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: FIREBASE_TIMEOUT),

        /// 生产模式，这里的值需要更改
        minimumFetchInterval: const Duration(seconds: 1),
      ));
    }

    return await config.fetchAndActivate().then((value) {
      //log("Remote Config fetchAndActivate激活完成，可以使用", icon: 'ok', time: true);
      return true;
    }).catchError((onError) {
      Tools.toast('无法连接到Google,部分功能将无法使用'.tr, type: 'error', time: 30);
      //log("Remote Config激活失败 = $onError", icon: 'error');
      return false;
    });
  }

  void fetch() {
    config.fetch().then((value) => log('Remote Config fetch远程获取完成，等待下次启动激活')).catchError((e) {
      Tools.toast('无法连接到Google,部分功能将无法使用'.tr, type: 'error', time: 30);
      //log('Remote Config fetch远程获取失败');
    });
  }

  String getString(String key) {
    String value = config.getString(key).trim();
    return value;
  }

  bool getBool(String key) {
    return config.getBool(key);
  }

  int getInt(String key) {
    return config.getInt(key);
  }

  getJson(String key) {
    String jsonString = config.getString(key).trim();
    return jsonDecode(jsonString);
  }
}
