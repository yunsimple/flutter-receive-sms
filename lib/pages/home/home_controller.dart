import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info/package_info.dart';
import '../../common/admob.dart';
import '../../common/local_storage.dart';
import '../../pages/my/my_controller.dart';
import '../../pages/phone/phone_detail_controller.dart';
import '../../request/http_utils.dart';
import '../../utils/api.dart';
import '../../utils/config.dart';
import '../../utils/tools.dart';
import 'package:upgrader/upgrader.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
  DateTime? lastPopTime;
  final defaultColor = Colors.grey;
  final activeColor = const Color(PRIMARYCOLOR);
  var curPage = 0.obs;
  final pageController = PageController(initialPage: 0);
  var phoneBadgeCount = 0.obs;
  var isMyBadgeShow = false.obs;
  static String appSwitch = '';
  late Upgrader updateInfo;
  var isUpgraderShow = false.obs; // 动态显示upgrader

  @override
  void onInit() async {
    log('HomeController onInit');
    super.onInit();
    WidgetsBinding.instance.addObserver(this); // 开屏广告 1.
    isMyBadgeShow.value = LocalStorage().getBool('isMyBadgeShow') ?? false;
    try {
      HttpUtils.post(Api.newPhone).then((response) {
        log('upcoming phone = $response');
        if (response['error_code'] == 0) {
          if(response['data']['newPhoneCount'] > 0){
            phoneBadgeCount.value = response['data'];
          }
          if(response['data']['upcomingPhoneCount'] > 0 || response['data']['vipPhoneCount'] > 0){
            final MyController myController = Get.find<MyController>();
            isMyBadgeShow.value = true;
            myController.phoneCount['vipPhoneCount'] = response['data']['vipPhoneCount'];
            myController.phoneCount['upcomingPhoneCount'] = response['data']['upcomingPhoneCount'];
            myController.phoneCount['favoritesPhoneCount'] = response['data']['favoritesPhoneCount'];
          }
        }
      }).catchError((e) {
        log('newPhone catchError 异常 = $e');
      });
    } on DioError catch (e) {
      log('newPhone DioError 异常 = $e');
    }

    // 准备更新widget
    upgrader();
  }

  @override
  void onClose() {
    super.onClose();
    WidgetsBinding.instance.removeObserver(this); // 开屏广告 3.
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    log("监控前后台切换" + state.toString());
    log("appSwitch = $appSwitch", time: true);
    if (state == AppLifecycleState.resumed) {
      final MyController myController = Get.find<MyController>();
      switch (appSwitch) {
        case 'rewarded':
          try {
            await HttpUtils.post(Api.coins).then((response) {
              if (response['error_code'] == 0) {
                var coins = response['data']['info']['coins'];
                if (coins != null) {
                  // 刷新当前页面的一些值
                  myController.userInfo['coins'] = coins;
                  if (Get.isRegistered<PhoneDetailController>()) {
                    final PhoneDetailController phoneDetailController = Get.find<PhoneDetailController>();
                    phoneDetailController.coins.value = coins;
                  }
                  Tools.toast('广告观看完成'.tr + '$coins');
                } else {
                  Tools.toast('广告观看完成'.tr + '${myController.userInfo['coins']}');
                }
              }
            }).catchError((e) {
              Tools.toast('广告观看完成'.tr + '${myController.userInfo['coins']}');
            });
          } on DioError catch (e) {
            Tools.toast('广告观看完成'.tr + '${myController.userInfo['coins']}');
          }
          break;
        case 'ad':
          break;
        case 'dialog':
          break;
        default:
          // open app广告弹出
          if (state == AppLifecycleState.resumed &&
              (DateTime.now().millisecondsSinceEpoch - Admob().appOpenAdShowTime) > ADMOB_OPENAPPAD_TIME_INTERVAAL) {
            if (Admob().appOpenAd == null) {
              Admob().getOpenApp('open_app');
            } else {
              Admob().showAppOpen();
            }
          }
          break;
      }
      appSwitch = '';
      log('清空appSwitch', time: true);
    }
  }

  // 返回更新upgrader类
  upgrader() {
    final versionUrl = Api.baseUrl + 'version.xml';
    final cfg = AppcastConfiguration(url: versionUrl, supportedOS: ['android']);
    updateInfo = Upgrader(
      appcastConfig: cfg,
      // todo 上线需要更改
      durationUntilAlertAgain: const Duration(days: 3),
      debugLogging: false,
    );
    updateInfo.initialize().then((value) {
      log('upgrader初始化');
      isUpgraderShow.value = true;
      checkVersion();
    });
  }

  checkVersion() async {
    // 检查版本，并对我的页面进行版本设置
    await PackageInfo.fromPlatform().then((value) {
      final MyController myController = Get.find<MyController>();
      myController.currentVersion.value = value.version;
      myController.storeVersion = updateInfo.currentAppStoreVersion();
      if (myController.storeVersion != null && myController.storeVersion != value.version) {
        myController.appStoreUrl = updateInfo.currentAppStoreListingURL();
        myController.isUpdate.value = true;
        isMyBadgeShow.value = true;
      } else {
        isMyBadgeShow.value = false;
      }
    });
  }
}
