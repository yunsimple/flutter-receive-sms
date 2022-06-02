import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../Routes.dart';
import '../../common/admob.dart';
import '../../common/auth.dart';
import '../../common/local_storage.dart';
import '../../common/notification.dart';
import '../../common/remote_config.dart';
import '../../request/http_utils.dart';
import '../../utils/api.dart';
import '../../utils/config.dart';
import '../../utils/tools.dart';

//倒计时 跳过 组件
class SplashView extends StatefulWidget {
  const SplashView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SplashState();
  }
}

class _SplashState extends State<SplashView> {
  //倒计时起始时间
  int _countTime = 8;
  //计时器
  late Timer _timer;
  String hintTitle = '加载中'.tr;
  int complete = 0;

  @override
  void initState() {
    super.initState();
    // 启动计时
    _startCountDownTime();

    init();
  }

  void init() async {
    // 业务加载
    if(mounted){
      setState(() {
        hintTitle = '系统初始化'.tr;
      });
    }

    // firebase初始化
    await Firebase.initializeApp();

    // 加载Admob广告
    /// todo 上线需要更改测试设备
    MobileAds.instance.initialize();
/*    MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: [
          '8473F26D124D76EAC5DB1A6F9E251D27',
          'EE5A97F180B7E142CBE2B5772EBA18B4'
        ]));*/

    // 初始化firebase Crashlytics错误收集
    if (kReleaseMode){ //
      //release
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    }

    // 初始化request类
    HttpUtils.init(
      baseUrl: Api.baseUrl,
    );

    // 初始化RemoteConfig
    await RemoteConfigApi().init();

    // 远程配置api请求地址
    String url = RemoteConfigApi().getString('baseUrl');
    if(url != ''){
      Api.baseUrl = url;
    }

    if(mounted){
      setState(() {
        hintTitle = '系统初始化成功'.tr;
      });
    }

    // 初始化密钥
    await Auth().getSalt();

    if(mounted){
      setState(() {
        hintTitle = '系统加载配置'.tr;
      });
    }

    // 请求notice数据
    if (RemoteConfigApi().getBool('noticeSwitch')) {
      try{
        HttpUtils.post(Api.notice).then((response) {
          if (response['error_code'] == 0 && response['data'].length > 0) {
            LocalStorage().setJSON('notice', response['data']);
          }
        }).catchError((e){
          //log('notice catchError 异常 = $e');
        });
      }on DioError catch (e){
        //log('notice DioError 请求出错 = $e');
      }
    }

    // 预加载首页原生广告
    Admob().getNativeAd('phone_list_native', isPreload: true, number: 3,);

    // FCM云消息
    fcm();

    // 初始化本地通知
    NotificationApi().init();

    if(mounted){
      setState(() {
        hintTitle = '正在进入系统'.tr;
      });
    }


    // 跳转首页,倒计时没过期前，加载所有数据
    //Get.offNamed(Routes.home);
    if(mounted){
      setState(() {
        _countTime = 2;
      });
    }

  }

  fcm() {
    // FCM云消息
    FirebaseMessaging.instance.getToken().then((value) => log('FCMtoken = $value'));

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      //log('fcm消息内容 = ${message.data}');

      if (message.notification != null) {
        //log('消息还包含通知 = ${message.notification}');

        RemoteNotification? notification = message.notification;
        // 显示本地通知
        if (notification != null && notification.android != null) {
          NotificationApi().show(title: notification.title, body: notification.body);
        }
      }
    });

    // 同步remote config 配置，供下次使用
    if(LocalStorage().getInt('startNumber')! > 1){
      RemoteConfigApi().fetch();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      //Stack层叠布局
      //alignment: AlignmentDirectional.center,
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(PRIMARYCOLOR),
          //alignment: AlignmentDirectional.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white,),
              const SizedBox(height: 10,),
              Text(hintTitle, style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  decoration: TextDecoration.none
              ),)
            ],
          )
        ),
        Positioned(
          child: GestureDetector(
            onTap: (){
              _timer.cancel();
              Get.offNamed(Routes.home);
            },
            child: Text(
              _countTime < 3 ? '$_countTime' : '',
              style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  decoration: TextDecoration.none
              ),
            ),
          ),
          top: 60,
          right: 20,
        )
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

//倒计时功能
  void _startCountDownTime() {
    //计时器刷新频率，每隔1s刷新一次
    const duration = Duration(seconds: 1);
    var callback = (timer) {
          setState(() {
            if (_countTime < 2) {
              //取消倒计时，并且跳转到首页
              _timer.cancel();
              Get.offNamed(Routes.home);
              //Navigator.pushNamed(context, "MainPage");
            } else {
              _countTime--;
            }
          });
        };

    //计时器实例
    _timer = Timer.periodic(duration, callback);
  }
}
