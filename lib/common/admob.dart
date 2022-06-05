import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../common/auth.dart';
import '../common/remote_config.dart';
import '../pages/home/home_controller.dart';
import '../utils/tools.dart';

class Admob {
  final int _maxFailedLoadAttempts = 3;
  static Map<String, NativeAd> _preloadNativeAd = {}; // 已经生效原生广告
  Map<String, NativeAd> _preloadNativeAdWait = {}; // 待生效原生广告

  RewardedAd? rewardedAd; // 激励广告
  RewardedInterstitialAd? rewardedInterstitialAd; // 插页式激励广告
  InterstitialAd? interstitialAd; // 插页广告
  BannerAd? bannerAnchoredAd; // banner锚定广告
  AppOpenAd? appOpenAd; // 开屏广告

  AdManagerBannerAd? bannerInlineAd;  // banner内嵌自适应广告
  AdSize? bannerInlineAdSize; // banner内嵌自适应广告大小
  AdManagerBannerAd? bannerInlineLeaderboardAd;  // banner内嵌自适应广告
  AdSize? bannerInlineLeaderboardAdSize; // banner内嵌自适应广告大小 728x90
  AdManagerBannerAd? bannerInlineMediumRectangleAd;  // banner内嵌自适应广告 中长方形
  AdSize? bannerInlineMediumRectangleAdSize; // banner内嵌自适应广告大小


  int appOpenAdShowTime = 0;  // 用于控制开屏广告展示频率
  int _numRewardedAdLoadAttempts = 0; // rewarded尝试次数
  int _numRewardedInterstitialAdLoadAttempts = 0; // rewarded尝试次数
  int _numInterstitialLoadAttempts = 0; // 插页式广告尝试次数

  static const _insets = 16.0;  //banner内嵌自适应广告
  double get inlineBannerAdWidth => MediaQuery.of(Get.context!).size.width - (2 * _insets);  ////banner内嵌自适应广告

  String nvAdSize = 'nativeBigAd'; // nativeAd广告模式
  final List<String> _nativeAdSize = ['nativeSmallAd', 'nativeBigAd']; // 原生广告模式选择
  late Map adSwitch; // 广告开关数组配置
  Orientation? currentOrientation;

  Admob._internal() {
    // 设置原生广告的 加载广告前，需要检查参数，配置
    adSwitch = RemoteConfigApi().getJson('adSwitch');
    nvAdSize = adSwitch['nativeSize'];
    log('adSwitch = $adSwitch');
  }

  static final Admob _instance = Admob._internal();
  factory Admob() {
    return _instance;
  }

  get preloadNativeAd => _preloadNativeAd;
  get preloadNativeAdWait => _preloadNativeAdWait;
  get nativeAdSize => _nativeAdSize;

  // 请求原生广告
  getNativeAd(String adTitle, {bool isPreload = true, int number = 1, String nvAdId = 'nativeSmallAd', id, adListener}) {
    if (!adSwitch['adSwitchNative']) {
      return false;
    }

    id ??= Tools.generateRandom(length: 6);

    // 预加载的情况
    if (isPreload) {
      int count = 0;
      for (var i = 0; i < number; i++) {
        _getNativeAd(adTitle, id: id, isPreload: isPreload, nvAdId: nvAdId, adListener: adListener);
        count++;
      }

      if (count == number) {
        return true;
      }
      return false;
    }

    //直接返回NativeAd情况
    return _getNativeAd(adTitle, id: id, isPreload: false, nvAdId: nvAdId, adListener: adListener);
  }

  // 请求原生广告
  NativeAd _getNativeAd(String adTitle,{required id, bool isPreload = true, String nvAdId = 'nativeSmallAd', adListener}) {
    log('请求native原生广告');
    NativeAd nativeAd = NativeAd(
      adUnitId: getAdUnitId(adTitle),
      factoryId: nvAdSize == 'random' ? _nativeAdSize[Random().nextInt(_nativeAdSize.length)] : nvAdId,
      request: const AdRequest(),
      listener: adListener ?? NativeAdListener(
        // 成功接收广告时调用。
        onAdLoaded: (value) {
          if (!isPreload) {
            // 不是预加载情况
            log('原生广告加载成功 id = $id');
          } else {
            // 预加载
            _preloadNativeAd[id] = _preloadNativeAdWait[id]!;
            log('预加载nativeAd成功$id 现有缓存 = ${_preloadNativeAd.length}');
            _preloadNativeAdWait.remove(id);
          }
        },
        // 当广告请求失败时调用。
        onAdFailedToLoad: (ad, error) {
          // 在此处处理广告以释放资源。
          // 从wait中移除
          _preloadNativeAdWait.remove(id);
          ad.dispose();
          log('原生广告请求失败，删除_preloadNativeAdWait = ${_preloadNativeAdWait.length} (code=${error.code} message=${error.message})');
        },
        // 当广告打开覆盖屏幕的叠加层时调用。
        onAdOpened: (Ad ad) {
          log('当广告打开覆盖屏幕的叠加层时调用');
        },
        // 当广告移除覆盖屏幕的叠加层时调用。
        onAdClosed: (Ad ad) {
          log('当广告移除覆盖屏幕的叠加层时调用。');
        },
        // 在广告上发生展示时调用。
        onAdImpression: (Ad ad) {
          log('在广告上发生展示时调用');
          // 加载成功后，预加载一个广告，存放起来
          // 并且移除_requestNativeAd相应的Id,防止再次使用
          _preloadNativeAd.remove(id);
          log('nativeAd移除成功 = $id 现有缓存 = ${_preloadNativeAd.length}');
          log('开始请求缓存广告');
          String title = Tools.generateRandom(length: 6);
          _preloadNativeAdWait[title] = _getNativeAd(adTitle, id: title, isPreload: true);

          // 广告显示成功后方法，用于判断屏蔽广告情况
          Tools.onAdShowFun();
        },
        // 在为 NativeAd 记录点击时调用。
        onNativeAdClicked: (NativeAd ad) {
          log('在为 NativeAd 记录点击时调用。');
          HomeController.appSwitch = 'ad';
        },
      ),
    );
    nativeAd.load();
    _preloadNativeAdWait[id] = nativeAd;
    return nativeAd;
  }

  // 请求激励广告
  getRewarded(String adTitle, {bool isPreload = true}) {
    if (!adSwitch['adSwitchRewarded']) {
      return false;
    }

    if (rewardedAd != null && !isPreload) {
      showRewarded();
      return;
    }
    RewardedAd.load(
      adUnitId: getAdUnitId(adTitle),
      request: const AdRequest(),
      serverSideVerificationOptions: ServerSideVerificationOptions(userId: Auth().currentUser?.uid),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          log("Rewarded加载完成");
          rewardedAd = ad;
          _numRewardedAdLoadAttempts = 0;
          if (!isPreload) {
            showRewarded();
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          log("Rewarded加载失败 = $error");
          _numRewardedAdLoadAttempts += 1;
          rewardedAd = null;
          if (_numRewardedAdLoadAttempts < _maxFailedLoadAttempts) {
            log('请求错误，重新请求');
            getRewarded(adTitle);
          }
        },
      ),
    );
  }

  // 显示激励广告
  void showRewarded() {
    if (rewardedAd == null) {
      log('激励广告不存在，请先加载');
      getRewarded('rewarded_coins', isPreload: false);
      return;
    }
    rewardedAd!.setImmersiveMode(true);
    rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        log('激励广告全屏显示');
        // 为了让open app广告不再出现
        HomeController.appSwitch = 'rewarded';
        rewardedAd = null;
        // 广告显示成功后方法，用于判断屏蔽广告情况
        Tools.onAdShowFun();
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        log('激励广告关闭,开始预加载下一个激励广告');
        ad.dispose();
        getRewarded('rewarded_coins');
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        log('激励广告未能全屏显示 = $error');
        ad.dispose();
        getRewarded('rewarded_coins');
      },
    );

    rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      log('激励广告已经观看，奖励(${reward.amount}, ${reward.type})',time: true);
    });
  }

  // 请求激励广告
  getRewardedInterstitial(String adTitle, {bool isPreload = true}) {
    log('开始请求插页式激励广告');
    if (!adSwitch['adSwitchRewarded']) {
      return false;
    }
    if (rewardedInterstitialAd != null && !isPreload) {
      showRewardedInterstitial();
      return;
    }

    RewardedInterstitialAd.load(
      adUnitId: getAdUnitId(adTitle),
      request: const AdRequest(),
      serverSideVerificationOptions: ServerSideVerificationOptions(userId: Auth().currentUser?.uid),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (RewardedInterstitialAd ad) {
          log("插页式激励广告加载完成");
          rewardedInterstitialAd = ad;
          _numRewardedInterstitialAdLoadAttempts = 0;
          if (!isPreload) {
            showRewardedInterstitial();
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          log("插页式激励广告加载失败 = $error");
          _numRewardedInterstitialAdLoadAttempts += 1;
          rewardedInterstitialAd = null;
          if (_numRewardedInterstitialAdLoadAttempts < _maxFailedLoadAttempts) {
            log('插页式激励广告 请求错误，重新请求');
            getRewardedInterstitial(adTitle);
          }
        },
      ),
    );
  }

  // 显示插页激励广告
  void showRewardedInterstitial() {
    if (rewardedInterstitialAd == null) {
      log('插页式激励广告不存在，请先加载');
      getRewardedInterstitial('rewarded_interstitial_coins', isPreload: false);
      return;
    }

    log('开始展示插页式激励广告');
    rewardedInterstitialAd!.setImmersiveMode(true);

    rewardedInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedInterstitialAd ad) {
        log('插页式激励广告全屏显示');
        rewardedInterstitialAd = null;

        // 广告显示成功后方法，用于判断屏蔽广告情况
        Tools.onAdShowFun();

        // 为了让open app广告不再出现
        HomeController.appSwitch = 'rewarded';
      },
      onAdDismissedFullScreenContent: (RewardedInterstitialAd ad) {
        log('插页式激励广告关闭,开始预加载下一个激励广告');
        ad.dispose();
        getRewardedInterstitial('rewarded_interstitial_coins');
      },
      onAdFailedToShowFullScreenContent: (RewardedInterstitialAd ad, AdError error) {
        log('插页式激励广告未能全屏显示 = $error');
        ad.dispose();
        getRewardedInterstitial('rewarded_interstitial_coins');
      },
    );

    rewardedInterstitialAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      log('插页式激励广告已经关看，奖励(${reward.amount}, ${reward.type})');
    });
  }

  // 请求插页广告
  getInterstitial(String adTitle, {bool isPreload = true}) {
    log('开始请求插页式广告');
    if (!adSwitch['adSwitchInterstitial']) {
      return false;
    }
    if (interstitialAd != null && !isPreload) {
      showInterstitialAd();
      return;
    }

    InterstitialAd.load(
        adUnitId: getAdUnitId(adTitle),
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            log('插页式广告加载完成');
            interstitialAd = ad;
            _numInterstitialLoadAttempts = 0;

            if (!isPreload) {
              showInterstitialAd();
            }
          },
          onAdFailedToLoad: (LoadAdError error) {
            log('插页式广告加载失败 = $error.');
            _numInterstitialLoadAttempts += 1;
            interstitialAd = null;
            if (_numInterstitialLoadAttempts < _maxFailedLoadAttempts) {
              getInterstitial('interstitial');
            }
          },
        ));
  }

  // 显示插页式广告
  void showInterstitialAd() {
    if (interstitialAd == null) {
      log('插页式广告没有加载成功');
      getInterstitial('interstitial');
      return;
    }

    interstitialAd!.setImmersiveMode(true);
    interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        log('插页式广告全屏显示');
        interstitialAd = null;

        // 广告显示成功后方法，用于判断屏蔽广告情况
        Tools.onAdShowFun();
        // 防止开屏广告打开
        HomeController.appSwitch = 'ad';
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        log('插页式广告关闭,开始预加载下一个广告');
        ad.dispose();
        getInterstitial('interstitial');
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        log('插页式广告未能全屏显示 = $error');
        ad.dispose();
        getInterstitial('interstitial');
      },
    );
    interstitialAd!.show();
    interstitialAd = null;
  }

  /// 锚定式横幅广告
  /// from 来自哪个页面的请求
  getBannerAnchored(String adTitle, {String from = 'Message', adListener}) async {
    log('开始请求锚定式横幅Banner广告');
    if (!adSwitch['adSwitchBanner']) {
      return false;
    }

    //currentOrientation = MediaQuery.of(Get.context!).orientation;
    //log('屏幕方向 = ${ MediaQuery.of(Get.context!).orientation}');
    // 如果存在先销毁，再新建
    await bannerAnchoredAd?.dispose();

    final AnchoredAdaptiveBannerAdSize? size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
        MediaQuery.of(Get.context!).size.width.truncate());

    if (size == null) {
      log('无法获得锚定横幅的高度。', icon: 'error');
      return;
    }

    bannerAnchoredAd = BannerAd(
      size: size,
      adUnitId: getAdUnitId(adTitle),
      request: const AdRequest(),
      listener: adListener ?? BannerAdListener(
        onAdLoaded: (Ad ad) {
          log('锚定广告加载完成 = ${ad.responseInfo}');
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          log('锚定广告加载失败 = $error',icon: 'error');
          ad.dispose();
          bannerAnchoredAd = null;
        },
        // 当广告打开覆盖屏幕的叠加层时调用。
        onAdOpened: (Ad ad) => log('锚定广告显示成功'),
        // 当广告移除覆盖屏幕的叠加层时调用。
        onAdClosed: (Ad ad) => log('锚定广告关闭'),
        // 在广告上发生展示时调用。
        onAdImpression: (Ad ad){
          log('锚定广告展示');

          // 广告显示成功后方法，用于判断屏蔽广告情况
          Tools.onAdShowFun();
        },
        onAdClicked: (Ad ad){
          HomeController.appSwitch = 'ad';
        }
      ),
    )..load();
    return bannerAnchoredAd;
  }

  // 内嵌式横幅广告
  getBannerInline(String adTitle, {AdSize size = AdSize.banner, adListener}) async {
    log('开始请求内嵌式横幅Banner广告,尺寸 = ${size.width} * ${size.height}');
    if (!adSwitch['adSwitchBanner']) {
      return false;
    }
    // 根据本机获取自适应的大小
    //AdSize localSize = AdSize.getCurrentOrientationInlineAdaptiveBannerAdSize(inlineBannerAdWidth.truncate());
    AdManagerBannerAd banner = AdManagerBannerAd(
      adUnitId: getAdUnitId(adTitle),
      sizes: [size],
      request: const AdManagerAdRequest(),
      listener: adListener ?? AdManagerBannerAdListener(
        onAdLoaded: (Ad ad) async {
          log('banner Admob页面回调，内嵌自适应广告加载成功: ${ad.responseInfo}');
          // 广告加载完成后，获取平台广告尺寸并使用
          // 更新容器的高度。 这是必要的，因为
          // 广告加载后高度可以改变。

          AdManagerBannerAd bannerAd = (ad as AdManagerBannerAd);
          final AdSize? size = await bannerAd.getPlatformAdSize();
          if (size == null) {
            log('错误：获取平台广告尺寸返回 null = $bannerAd', icon: 'error');
            return;
          }
          if(size == AdSize.leaderboard){
            bannerInlineLeaderboardAdSize = size;
          }else if(size == AdSize.mediumRectangle){
            bannerInlineMediumRectangleAdSize = size;
          }else{
            bannerInlineAdSize = size;
          }
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          log('banner内嵌自适应广告加载失败 = $error');
          ad.dispose();
        },
        // 当广告打开覆盖屏幕的叠加层时调用。
        onAdOpened: (Ad ad) => log('内嵌式横幅广告打开覆盖屏幕的叠加层时调用。'),
        // 当广告移除覆盖屏幕的叠加层时调用。
        onAdClosed: (Ad ad) => log('内嵌式横幅广告移除覆盖屏幕的叠加层时调用。'),
        // 在广告上发生展示时调用。
        onAdImpression: (Ad ad){
          log('内嵌式横幅广告上发生展示时调用');
          log("内嵌横幅广告ID = ${ad.responseInfo?.responseId}");
          //getBannerInline();

          // 广告显示成功后方法，用于判断屏蔽广告情况
          Tools.onAdShowFun();
        },
        onAdClicked: (Ad ad){
          HomeController.appSwitch = 'ad';
        }
      ),
    );
    await banner.load();

    if(size == AdSize.leaderboard){
      bannerInlineLeaderboardAd = banner;
    }else if(size == AdSize.mediumRectangle){
      bannerInlineMediumRectangleAd = banner;
    }else{
      bannerInlineAd = banner;
    }

  }

  // 开屏广告
  getOpenApp(String adTitle, {isPreload = true}) {
    log('开始请求开屏广告');
    if (!adSwitch['adSwitchBanner']) {
      return false;
    }

    AppOpenAd.load(
        adUnitId: getAdUnitId(adTitle),
        request: const AdRequest(),
        orientation: AppOpenAd.orientationPortrait,
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            log('开屏广告加载成功 = $ad');
            appOpenAd = ad;
            if(!isPreload){
              showAppOpen();
            }
          },
          onAdFailedToLoad: (error) {
            log('开屏广告加载失败 = $error', icon: 'error');
            // Handle the error.
          },
        ),
    );
  }

  void showAppOpen() {
    log('开始展示开屏广告');
    if(appOpenAd == null){
      getOpenApp('open_app');
      return;
    }
    appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) async {
        log('开屏广告显示全屏内容');
        appOpenAdShowTime = DateTime.now().millisecondsSinceEpoch;

        // 广告显示成功后方法，用于判断屏蔽广告情况
        Tools.onAdShowFun();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        log('开屏广告未能显示全屏内容 = $error', icon: 'error');
        ad.dispose();
        appOpenAd = null;
      },
      onAdDismissedFullScreenContent: (ad) {
        log('关闭开屏广告，开始预加载');
        ad.dispose();
        appOpenAd = null;
        getOpenApp('open_app');
      },
      onAdClicked: (Ad ad){
        HomeController.appSwitch = 'ad';
      }
    );
    appOpenAd!.show();
  }

  // admob广告id
  String getAdUnitId(String adTitle){
    switch(adTitle){

      case 'message_bottom_banner':{
        if (Platform.isAndroid) {
          return 'ca-app-pub-5224126064747013/7585497272';
        } else if (Platform.isIOS) {
          return '';
        }
      }
      break;

      case 'phone_list_native':{
        if (Platform.isAndroid) {
          //return 'ca-app-pub-3940256099942544/2247696110'; // 测试
          return 'ca-app-pub-5224126064747013/8864854158';
        } else if (Platform.isIOS) {
          return '';
        }
      }
      break;

      case 'rewarded_coins':{
        if (Platform.isAndroid) {
          return 'ca-app-pub-5224126064747013/5892060081';
        } else if (Platform.isIOS) {
          return '';
        }
      }
      break;

      case 'rewarded_interstitial_coins':{
        if (Platform.isAndroid) {
          return 'ca-app-pub-5224126064747013/5078506016';
        } else if (Platform.isIOS) {
          return '';
        }
      }
      break;

      case 'country_list_native':{
        if (Platform.isAndroid) {
          return 'ca-app-pub-5224126064747013/3962495771';
        } else if (Platform.isIOS) {
          return '';
        }
      }
      break;

      case 'email_banner':{
        if (Platform.isAndroid) {
          return 'ca-app-pub-5224126064747013/6724390486';
        } else if (Platform.isIOS) {
          return '';
        }
      }
      break;

      case 'email_detail_banner':{
        if (Platform.isAndroid) {
          return 'ca-app-pub-5224126064747013/7323156287';
        } else if (Platform.isIOS) {
          return '';
        }
      }
      break;

      case 'message_list_native':{
        if (Platform.isAndroid) {
          return 'ca-app-pub-5224126064747013/4453450361';
        } else if (Platform.isIOS) {
          return '';
        }
      }
      break;

      case 'open_app':{
        if (Platform.isAndroid) {
          return 'ca-app-pub-5224126064747013/8608317796';
        } else if (Platform.isIOS) {
          return '';
        }
      }
      break;

      case 'interstitial':{
        if (Platform.isAndroid) {
          return 'ca-app-pub-5224126064747013/9917530034';
        } else if (Platform.isIOS) {
          return '';
        }
      }
      break;

      case 'message_upcoming_banner':{
        if (Platform.isAndroid) {
          return 'ca-app-pub-5224126064747013/7327025714';
        } else if (Platform.isIOS) {
          return '';
        }
      }
      break;

    }

    throw UnsupportedError("Unsupported platform");
  }

}
