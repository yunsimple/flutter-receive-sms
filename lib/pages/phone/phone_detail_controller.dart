import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../common/admob.dart';
import '../../common/remote_config.dart';
import '../../pages/home/home_controller.dart';
import '../../pages/my/my_controller.dart';
import '../../request/http_utils.dart';
import '../../utils/api.dart';
import '../../utils/tools.dart';

class PhoneDetailController extends GetxController {
  final EasyRefreshController refreshController = EasyRefreshController();
  final ScrollController scrollController = ScrollController(); // 滚动
  var isShowFloatBtn = false.obs; // 是否显示返回顶部按钮
  late String phone;
  RxList<dynamic> messageList = RxList([]);
  RxBool showEmpty = RxBool(false);
  RxMap currentPhoneInfo = RxMap({});
  int page = 1;
  var isBannerShow = false.obs;
  var isAdShowList = [].obs;
  var numberType = 1.obs; // 号码类型，1普通展示号码，2预告号码，3vip号码
  int upcomingSecond = 0; // 预告号码剩余秒数
  var isMiddleBannerShow = false.obs; //预告号码下面banner广告
  List<int> insertIndex = [1, 4, 10, 15]; // 插入广告的下标
  int defaultLength = 20; // 每页短信内容数量
  int requestError = 0;
  var isFavoritesShow = false.obs; // 动态是否显示收藏标签
  var isOnline = true.obs; // 是否是在线号码
  var coins = 0.obs; // 用户分数
  var price = 50.obs; //号码单价
  var rewardCoins = 10; // admob上设置的激励广告奖励数量
  var countdownTitle = '号码上线倒计时'.tr.obs;
  late int upcomingTime = 0;
  bool isLoad = false;

  ///在onInit()接受传递的数据
  @override
  void onInit() {
    super.onInit();
    currentPhoneInfo.value = Get.arguments;
    phone = currentPhoneInfo['phone_num'];
    fetchMessageList(phone);
    // 监听滚动
    _initScrollEvent();
  }

  ///如果接收的数据需要刷新到界面上，请在onReady回调里面接收数据操作，
  ///onReady是在addPostFrameCallback回调中调用，刷新数据的操作在onReady进行，
  ///能保证界面是初始加载完毕后才进行页面刷新操作的
  @override
  void onReady() async {
    super.onReady();

    // 激励广告奖励积分配置
    rewardCoins = RemoteConfigApi().getInt('adRewardedCoins');

    // 弹出式插页广告
    adPopup();


    Admob().getBannerAnchored('message_bottom_banner',
        adListener: BannerAdListener(onAdLoaded: (Ad ad) {
          log('锚定广告加载完成，外部回调');
          isBannerShow.value = true;
        }, onAdFailedToLoad: (Ad ad, LoadAdError error) {
          log('锚定广告加载失败，外部回调 = $error', icon: 'error');
          ad.dispose();
          Admob().bannerAnchoredAd = null;
        }, onAdClicked: (Ad ad) {
          HomeController.appSwitch = 'ad';
        }, onAdImpression: (Ad ad) {
          Tools.onAdShowFun();
        }));

    if (Admob().bannerInlineMediumRectangleAdSize != null) {
      isMiddleBannerShow.value = true;
    }
  }

  adPopup() {
    // 弹出插页式广告配置
    var adPopupConfig = RemoteConfigApi().getJson('adPopup');
    //log('adPopup = $adPopupConfig');

    // 开始弹出广告
    if (adPopupConfig['isShow']) {
      if (adPopupConfig['showMode'] == 'every') {
        // 每次点击都会显示
        selectAd(adPopupConfig);
      } else if (adPopupConfig['showMode'] == 'random') {
        // 根据随机百分比按概率显示
        if (Tools.isSelect(adPopupConfig['percentage'])) {
          selectAd(adPopupConfig);
        }
      }
    }
  }

  selectAd(adPopupConfig) {
    if (Tools.isSelect(adPopupConfig['rewardedPercentage'])) {
      // 根据rewardedPercentage的百分比，选择显示哪个广告
      if (Admob().rewardedAd == null) {
        log('message 开始预加载激励插页式广告');
        Admob().getRewardedInterstitial('rewarded_interstitial_coins');
      } else {
        log('message 开始显示激励插页式广告');
        Admob().showRewardedInterstitial();
      }
    } else {
      if (Admob().interstitialAd == null) {
        log('message 开始预加载插页式广告');
        Admob().getInterstitial('interstitial');
      } else {
        log('message 开始显示插页式广告');
        Admob().showInterstitialAd();
      }
    }
  }

  @override
  onClose() {
    super.onClose();
    isBannerShow.value = false;
    scrollController.dispose();
    refreshController.dispose();
  }

  void _initScrollEvent() {
    scrollController.addListener(() {
      if (scrollController.offset < 1000 && isShowFloatBtn.isTrue) {
        isShowFloatBtn.value = false;
      } else if (scrollController.offset >= 1000 && isShowFloatBtn.isFalse) {
        isShowFloatBtn.value = true;
      }
    });
  }

  //获取随机号码
  fetchRandomPhone() async {
    Map<String, dynamic> randomPhone = await HttpUtils.post(Api.getRandom).catchError((e) {
      if (requestError > 3) {
        Tools.toast('请求失败'.tr, type: 'error');
      }
    });
    if (randomPhone['error_code'] == 0) {
      currentPhoneInfo.value = randomPhone['data'];
      return randomPhone['data'];
    } else {
      return false;
    }
  }

  //获取短信内容
  fetchMessageList(String phone, {int page = 1}) async {
    Map<String, dynamic>? params = {'phone': phone, 'page': page};
    try {
      await HttpUtils.post(Api.getMessage, data: params).then((response) async {
        if (response['error_code'] == 0 && response['data']['message'].length > 0) {
          numberType.value = 1;
          if (page == 1 && messageList.isNotEmpty) {
            messageList.clear();
            isAdShowList = [].obs;
          }

          var messageData = Tools.insertNativeAd(dataList: response['data']['message'], insertIndex: insertIndex);
          messageList.addAll(messageData);

          await Future.delayed(const Duration(milliseconds: 50));

          if (page == 1 && messageList.isNotEmpty) {
            for (var value in insertIndex) {
              isAdShowList.add(value);
            }
            //log('isAdShowList = $isAdShowList');
          }
          showEmpty.value = false;
        } else if (response['error_code'] == 3000) {
          // 数据为空
          error();
        } else if (response['error_code'] == 3003) {
          // 预告号码
          numberType.value = 2;

          if (response['data']['info']['upcomingTime'] != null) {
            // 计算出秒数，进行倒计时
            int time = int.parse(response['data']['info']['upcomingTime']);
            int nowTime = (DateTime.now().millisecondsSinceEpoch / 1000).round();
            upcomingSecond = time - nowTime;
            if (upcomingSecond < 0) {
              countdownTitle.value = '加载中'.tr + '...';
            }
          }

          // 加载广告
          log('开始请求预告下面banner广告');
          Admob().getBannerInline('message_upcoming_banner', size: AdSize.mediumRectangle, adListener: adListener());
        } else if (response['error_code'] == 3004) {
          // vip 号码
          numberType.value = 3;

          var reCoins = response['data']['info']['coins'];
          if (reCoins != null) {
            coins.value = reCoins;
            final MyController myController = Get.find<MyController>();
            myController.userInfo['coins'] = reCoins;
          }

          // 单价
          var rePrice = response['data']['info']['price'];
          if (rePrice != null) {
            price.value = rePrice;
          }
        }

        // 是否收藏
        if (response['data']['info']['favorites'] != null) {
          isFavoritesShow.value = response['data']['info']['favorites'];
        }
        // 是否在线
        bool? resultOnline = response['data']['info']['online'];
        if (resultOnline != null) {
          isOnline.value = resultOnline;
        }

        // 加载广告
        log('开始请求预告下面banner广告');
        Admob().getBannerInline('message_upcoming_banner', size: AdSize.mediumRectangle, adListener: adListener());
        if (Admob().rewardedAd == null) {
          Admob().getRewarded('rewarded_coins');
        }
      }).catchError((e) {
        log('getMessage catchError 异常 = $e');
        error();
      });
    } on DioError catch (e) {
      log('getMessage DioError 异常 = $e');
      error();
    } catch (e) {
      log('getMessage 异常 = $e');
      error();
    }
  }

  // 购买vip号码
  Future<bool> buyVipNumber() async {
    // 远程请求
    var response = await HttpUtils.post(Api.buyNumber, data: {'phone': phone}).catchError((e) {
      log('buyNumber catchError 异常 = $e');
    });
    final MyController myController = Get.find<MyController>();
    if (response['error_code'] == 0) {
      var reCoins = response['data']['info']['coins'];
      if (reCoins != null) {
        coins.value = reCoins;
        myController.userInfo['coins'] = reCoins;
      }
      return true;
    } else if (response['error_code'] == 3005) {
      var reCoins = response['data']['info']['coins'];
      if (reCoins != null) {
        coins.value = reCoins;
        myController.userInfo['coins'] = reCoins;
      }
      Tools.toast('当前金币不足观看广告获取更多金币'.tr, type: 'info');
      return false;
    }

    return false;
  }

  // 收藏号码
  void switchFavorites() {
    try {
      if (isFavoritesShow.isTrue) {
        HttpUtils.post(Api.favoritesDel, data: {'phone': phone}).then((response) {
          if (response['error_code'] == 0) {
            isFavoritesShow.value = false;
          }
        }).catchError((e) {
          Tools.toast('请求失败'.tr, type: 'error');
        });
      } else {
        HttpUtils.post(Api.favorites, data: {'phone': phone}).then((response) {
          if (response['error_code'] == 0) {
            isFavoritesShow.value = true;
          }
        }).catchError((e) {
          Tools.toast('请求失败'.tr, type: 'error');
        });
      }
    } on DioError catch (e) {
      log(e);
    }
  }

  // 提交号码无法访问
  report() async {
    try {
      HttpUtils.post(Api.report, data: {'phone': phone}).then((response) {
        if (response['error_code'] == 0) {
          Tools.toast('反馈成功'.tr);
        }
      }).catchError((e) {
        log('report catchError 异常 = $e');
        Tools.toast('反馈失败'.tr, type: 'error');
      });
    } on DioError catch (e) {
      log('report DioError 异常 = $e');
      Tools.toast('反馈失败'.tr);
    }
  }

// dio返回错误处理
  error() {
    if (messageList.isEmpty) {
      if (requestError > 3) {
        showEmpty.value = true;
      }
      requestError++;
    }
  }

  // 预告号码下面广告监听
  AdManagerBannerAdListener adListener() {
    return AdManagerBannerAdListener(onAdLoaded: (Ad ad) async {
      log('banner 预告号码下面广告，内嵌自适应广告加载成功: ${ad.responseInfo}');
      // 广告加载完成后，获取平台广告尺寸并使用
      // 更新容器的高度。 这是必要的，因为
      // 广告加载后高度可以改变。

      AdManagerBannerAd bannerAd = (ad as AdManagerBannerAd);
      final AdSize? size = await bannerAd.getPlatformAdSize();
      if (size == null) {
        log('错误：获取平台广告尺寸返回 null = $bannerAd', icon: 'error');
        return;
      }
      Admob().bannerInlineMediumRectangleAdSize = size;
      isMiddleBannerShow.value = true;
    }, onAdFailedToLoad: (Ad ad, LoadAdError error) {
      log('banner预告号码下面广告，内嵌自适应广告加载失败 = $error');
      ad.dispose();
    },
        // 在广告上发生展示时调用。
        onAdImpression: (Ad ad) {
      log('banner预告号码下面广告，内嵌式横幅广告上发生展示时调用');
      Tools.onAdShowFun();
    }, onAdClicked: (Ad ad) {
      HomeController.appSwitch = 'ad';
    });
  }
}
