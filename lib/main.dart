import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../Routes.dart';
import '../../common/language.dart';
import '../../pages/country/country_controller.dart';
import '../../pages/country/country_view.dart';
import '../../pages/email/email_controller.dart';
import '../../pages/email/email_detail_controller.dart';
import '../../pages/email/email_detail_view.dart';
import '../../pages/email/email_view.dart';
import '../../pages/home/home_view.dart';
import '../../pages/login/login_controller.dart';
import '../../pages/login/login_view.dart';
import '../../pages/login/register_controller.dart';
import '../../pages/login/register_view.dart';
import '../../pages/my/my_controller.dart';
import '../../pages/my/my_view.dart';
import '../../pages/phone/phone_controller.dart';
import '../../pages/phone/phone_detail_controller.dart';
import '../../pages/phone/phone_detail_view.dart';
import '../../pages/phone/phone_list_controller.dart';
import '../../pages/phone/phone_list_view.dart';
import '../../pages/phone/phone_view.dart';
import '../../pages/splash/splash_view.dart';
import '../../utils/config.dart';
import '../../utils/tools.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;
import 'common/local_storage.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

Future<void> main() async {
  //设置顶部主题颜色
  SystemUiOverlayStyle uiStyle = SystemUiOverlayStyle.light.copyWith(
    statusBarColor: Tools.createMaterialColor(const Color(PRIMARYCOLOR)),
  );
  SystemChrome.setSystemUIOverlayStyle(uiStyle);

  // 必须放在前面
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化本地存储类
  await LocalStorage().init();

  // 记录第一次启动时间
  if(LocalStorage().getInt('startTime') == null){
    LocalStorage().setInt('startTime', DateTime.now().millisecondsSinceEpoch);
  }
  // 记录启动次数
  LocalStorage().setIncr('startNumber');

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 如果您要在后台使用其他 Firebase 服务，例如 Firestore，
  // 确保在使用其他 Firebase 服务之前调用 `initializeApp`。
  //await Firebase.initializeApp();

  //log("接收到firebase messaging后台消息 = ${message.messageId}");
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter message',
      initialRoute: Routes.splash,
      translations: Language(), // 语言包
      locale: language(), //设置默认语言
      fallbackLocale: const Locale("en", 'US'), // 在配置错误的情况下,使用的语言
      theme: ThemeData(
          primarySwatch: Tools.createMaterialColor(const Color(PRIMARYCOLOR)),
          textTheme: GoogleFonts.montserratTextTheme(
            Theme.of(context).textTheme,
          )),
      getPages: [
        GetPage(name: Routes.splash, page: () => const SplashView()),
        GetPage(name: Routes.home, page: () => const HomeView(), binding: HomeBinding()),
        GetPage(name: Routes.phone, page: () => const PhoneView(), binding: PhoneBinding()),
        GetPage(name: Routes.phoneList, page: () => const PhoneListView(), binding: PhoneListBinding()),
        GetPage(name: Routes.phoneDetail, page: () => const PhoneDetailView(), binding: PhoneDetailBinding()),
        GetPage(name: Routes.country, page: () => const CountryView(), binding: CountryBinding()),
        GetPage(name: Routes.email, page: () => EmailView(), binding: EmailBinding()),
        GetPage(name: Routes.my, page: () => const MyView(), binding: MyBinding()),
        GetPage(name: Routes.emailDetail, page: () => const EmailDetailView(), binding: EmailDetailBinding()),
        GetPage(name: Routes.login, page: () => LoginView(), binding: LoginBinding()),
        GetPage(name: Routes.register, page: () => RegisterView(), binding: RegisterBinding()),
      ],
      enableLog: false,
      builder: EasyLoading.init(),

    );
  }

  language() {
    var language = LocalStorage().getJSON('language');
    Locale lang;
    if (language == null) {
      log('语言缓存不存在，默认为系统自动');
      lang = ui.window.locale;
    } else {
      log('语言缓存存在，设置${language['languageCode']}');
      lang = Locale(language['languageCode'], language['countryCode']);
    }
    return lang;
  }
}

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MyController(), fenix: true);
    Get.lazyPut(() => PhoneController(), fenix: true);
    Get.lazyPut(() => CountryController(), fenix: true);
    Get.lazyPut(() => EmailController(), fenix: true);
  }
}

class PhoneBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => PhoneController());
  }
}

class CountryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CountryController());
  }
}

class EmailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => EmailController());
  }
}

class MyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MyController());
  }
}

class EmailDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => EmailDetailController());
  }
}

class PhoneDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => PhoneDetailController());
  }
}

class PhoneListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => PhoneListController());
  }
}

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LoginController());
  }
}

class RegisterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RegisterController());
  }
}
