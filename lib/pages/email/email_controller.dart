import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../common/admob.dart';
import '../../common/notification.dart';
import '../../pages/home/home_controller.dart';
import '../../request/http_utils.dart';
import '../../utils/api.dart';
import '../../utils/config.dart';
import '../../utils/tools.dart';
import 'package:get/get.dart';

class EmailController extends GetxController with StateMixin<dynamic> {
  final String title = '临时邮箱'.tr;
  List<String> mailSiteList = <String>["@"].obs;
  List<DropdownMenuItem<String>> dropDownItem =
      <DropdownMenuItem<String>>[const DropdownMenuItem(child: Text("loading"), value: "loading")].obs;
  RxString currentEmailSite = RxString('');
  RxString currentEmailUser = RxString('');
  String? emailAddress;
  RxList<dynamic> emailList = RxList([]);
  RxInt lastEmailTime = RxInt(0);
  var isBannerShow = false.obs;
  var isShowEmpty = false.obs;
  int requestError = 0;
  var autoRequestRunning = false.obs; // 自动请求邮件是否正在运行
  var autoButton = '自动获取'.tr.obs;

  @override
  void onInit() async {
    super.onInit();
    Admob().getBannerInline('email_banner',
        size: AdSize.leaderboard,
        adListener: AdManagerBannerAdListener(onAdLoaded: (Ad ad) async {
          log('banner外部回调，内嵌自适应广告加载成功: ${ad.responseInfo}');

          AdManagerBannerAd bannerAd = (ad as AdManagerBannerAd);
          final AdSize? size = await bannerAd.getPlatformAdSize();
          if (size == null) {
            log('错误：获取平台广告尺寸返回 null = $bannerAd', icon: 'error');
            return;
          }
          Admob().bannerInlineLeaderboardAdSize = size;
          isBannerShow.value = true;
        }, onAdFailedToLoad: (Ad ad, LoadAdError error) {
          log('banner内嵌自适应广告加载失败 = $error');
          ad.dispose();
        }, onAdImpression: (Ad ad) {
          Tools.onAdShowFun();
        }, onAdClicked: (Ad ad) {
          log('点击了广告');
          HomeController.appSwitch = 'ad';
        }));
  }

  ///删除当前使用的邮箱,初始化
  Future<bool> deleteEmail() {
    if (autoRequestRunning.isFalse) {
      currentEmailUser.value = "";
      emailAddress = null;
      emailList.clear();
      lastEmailTime = RxInt(0);
      autoRequestRunning.value = false;
      autoButton.value = '自动获取'.tr;
      Tools.toast('删除成功'.tr);
      return Future.value(true);
    } else {
      Tools.toast('正在使用中,如需更换,请先销毁'.tr, type: 'info');
      return Future.value(false);
    }
  }

  void setCurrentItem(value) {
    if(currentEmailSite.isNotEmpty){
      currentEmailSite.value = value;
    }
  }

  void setCurrentUsername(value) {
    currentEmailUser.value = value;
  }

  // 自动请求邮件
  autoEmailList() async {
    for (var i = 0; i < EMAIL_AUTO_REQUEST_NUMBER; i++) {
      log('自动请求邮件次数 $i');
      autoButton.value = '自动获取'.tr + '(${EMAIL_AUTO_REQUEST_NUMBER - i})';
      var isGetEmail = await fetchEmailList();
      log('isGetEmail = $isGetEmail');
      if (isGetEmail == true) {
        NotificationApi().show(title: '收到新邮件'.tr, body: emailList[0]['subject']);
        break;
      }
      await Future.delayed(const Duration(seconds: EMAIL_AUTO_DELAY_SECOND));
    }
    autoRequestRunning.value = false;
    autoButton.value = '自动获取'.tr;
    return true;
  }

  //获取邮件内容
  fetchEmailList() async {
    Map<String, dynamic>? params = {'email': emailAddress};
    try {
      return await HttpUtils.post(Api.getEmailList, data: params).then((response) {
        log('邮件https请求成功');
        if (response['error_code'] == 0 && response['data'].length > 0) {
          //获取到了邮件，根据lastEmailTime遍历是否为新邮件
          int insertCount = 0;
          requestError = 0;
          for (int i = 0; i < response['data'].length; i++) {
            int lastTime = response['data'][i]['time'];
            if (lastEmailTime != RxInt(lastTime) && lastEmailTime < lastTime) {
              emailList.insert(i, response['data'][i]);
              insertCount++;
            } else {
              break;
            }
          }

          if (insertCount > 0) {
            lastEmailTime = RxInt(response['data'][0]['time']);
            Tools.toast('收到新邮件'.tr);
            isShowEmpty.value = true;

            /// 加载邮件列表banner广告
            if (Admob().bannerInlineMediumRectangleAdSize == null) {
              Admob().getBannerInline('email_detail_banner', size: AdSize.mediumRectangle);
            }
            return true;
          } else {
            if (autoRequestRunning.isFalse) Tools.toast('暂未收到新邮件'.tr, type: 'info');
          }
        } else if (response['error_code'] == 3000) {
          if (autoRequestRunning.isFalse) Tools.toast('暂未收到新邮件'.tr, type: 'info');
        }
      }).catchError((e) {
        log(e.toString());
        requestError++;
        if (requestError > 2) {
          if (autoRequestRunning.isFalse) Tools.toast('请求失败'.tr, type: 'error');
        }
      });
    } on DioError catch (e) {
      log('getEmailList DioError 异常 = $e');
    }
  }

  //申请邮箱
  Future<bool> fetchEmailAddress({String type = 'random'}) async {
    Map<String, dynamic>? params = {'site': currentEmailSite.toString()};
    if (type != 'random') {
      params['email_name'] = currentEmailUser.toString();
    }

    try {
      var response = await HttpUtils.post(Api.getEmailAddress, data: params);
      if (response['error_code'] == 0) {
        String email = response['data'];
        emailAddress = response['data'];
        List<String> emailList = email.split("@");
        currentEmailUser.value = emailList[0];
        currentEmailSite.value = "@" + emailList[1];
        Tools.toast(email + '邮箱创建成功'.tr);
        return Future<bool>.value(true);
      } else {
        Tools.toast('请求失败'.tr, type: 'error');
        return Future<bool>.value(false);
      }
    } on DioError catch (e) {
      //获取失败情况
      Tools.toast('请求失败'.tr, type: 'error');
      return Future<bool>.value(false);
    } catch (e) {
      log('捕获dio其他异常');
      return Future<bool>.value(false);
    }
  }

  //获取邮箱列表
  void fetchMailList() async {
    if (mailSiteList.first == "@") {
      try {
        await HttpUtils.post(Api.getMailSite, options: buildCacheOptions(const Duration(days: 1))).then((response) {
          if(response['error_code'] == 0){
            mailSiteList.removeAt(0);
            mailSiteList = response['data'].cast<String>();
            dropDownItem.removeAt(0);
            currentEmailSite.value = "@" + mailSiteList[0];
            for (var value in mailSiteList) {
              dropDownItem.add(DropdownMenuItem(child: Text("@$value"), value: "@$value"));
            }
            update(['emailSite']);
          }
        }).catchError((e){
          log('getMailSite catchError 异常');
        });
      } on DioError catch (e) {
        //获取失败情况
        //Tools.toast('请求失败'.tr, type: 'error');
        log('getMailSite DioError 异常');
      }
    }
  }
}
