import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../utils/tools.dart';
import '../pages/home/home_controller.dart';

class NotificationApi {
  static NotificationApi? _instance;
  final _notifications = FlutterLocalNotificationsPlugin();
  //final onNotifications = BehaviorSubject<String?>(); // 用于点击notification后跳转页面

  factory NotificationApi() {
    _instance ??= NotificationApi._config();
    return _instance!;
  }

  NotificationApi._config();

  //初始化
  init() {
    _notifications
        .initialize(const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
            onSelectNotification: (payload) async {
      //onNotifications.add(payload);
      log('打开本地通知 = $payload');
      final HomeController homeController = Get.find<HomeController>();
      switch (payload) {
        case 'phone':
          int page = 0;
          homeController.pageController.jumpToPage(page);
          homeController.curPage.value = page;
          break;
        case 'country':
          int page = 1;
          homeController.pageController.jumpToPage(page);
          homeController.curPage.value = page;
          break;
        case 'email':
          int page = 2;
          homeController.pageController.jumpToPage(page);
          homeController.curPage.value = page;
          break;
        case 'my':
          int page = 3;
          homeController.pageController.jumpToPage(page);
          homeController.curPage.value = page;
          break;
        default:
          int page = 0;
          homeController.pageController.jumpToPage(page);
          homeController.curPage.value = page;
          break;
      }
    });
  }

  _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails('1', 'New message',
          channelDescription: 'New message alert',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker'),
      iOS: IOSNotificationDetails(),
    );
  }

  Future show({required String? title, required String? body, String? payload, int id = 0}) async {
    _notifications.show(
      id,
      title,
      body,
      _notificationDetails(),
      payload: payload,
    );
  }
}
