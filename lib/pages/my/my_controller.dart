import 'package:ReceiveSMS/common/loading.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../common/auth.dart';
import '../../common/local_storage.dart';
import '../../pages/home/home_controller.dart';
import '../../request/http_utils.dart';
import '../../utils/api.dart';
import '../../utils/tools.dart';
import 'package:url_launcher/url_launcher.dart';


class MyController extends GetxController {
  final String title = '个人中心'.tr;
  //var userInfo = Rx<User?>(Auth().currentUser);
  var email = ''.obs;
  var userInfo = {}.obs;
  var myInfo = {}.obs;
  var avatar = ''.obs;
  var isEmailVerified = false.obs;
  String currentLanguage = 'System';
  var isUpdate = false.obs; // 是否显示更新红点
  String? appStoreUrl;
  var currentVersion = ''.obs;
  String? storeVersion;
  final HomeController homeController = Get.find<HomeController>();
  var phoneCount = {'vipPhoneCount': 0, 'upcomingPhoneCount': 0, 'favoritesPhoneCount': 0}.obs;  // 各号码数量动态列表
  var isLoading = false.obs;

  @override
  void onInit() async {
    log('MyController onInit');
    super.onInit();
    getMy();
    var language = LocalStorage().getJSON('language');
    if(language == null){
      currentLanguage = 'System';
    }else{
      if(language['languageCode'] == 'zh') currentLanguage = '繁體中文';
      if(language['languageCode'] == 'en') currentLanguage = 'English';
      if(language['languageCode'] == 'de') currentLanguage = 'Deutsch';
      if(language['languageCode'] == 'pt') currentLanguage = 'Português';
    }
  }

  @override
  void onReady() async {
    super.onReady();
    /// 如果没有登陆，包括匿名登陆，直接显示要登陆
    log('MyController onReady');
    log('开始检查是否有登陆用户，匿名用户不算');
    var firebaseEmail = Auth.firebaseUserInfo?.email;
    if(firebaseEmail != null){
      email.value = firebaseEmail;
    }
    var firebaseAvatar = Auth.firebaseUserInfo?.photoURL;
    if(firebaseAvatar != null){
      avatar.value = firebaseAvatar;
    }
  }

  getMy() async {
    try{
      await HttpUtils.post(Api.getMy).then((response){
        if(response['error_code'] == 0 && response['data'] != null){
          myInfo.value = response['data'];
          // userInfo
          userInfo.value = response['data']['userInfo'];

        }
      }).catchError((e){
        log('getMy catchError 异常 = $e');
      });
    } on DioError catch (e){
      log('getMy DioError 异常 = $e');
    } catch (e){
      log('getMy 异常 = $e');
    }
  }

  /// 登陆
  login() async {
    String? oldUserID = Auth().currentUser?.uid;
    await Get.toNamed(Api.login)?.then((value) async {
      log('登陆成功返回 = $value');
      if (value == 'LoginSuccess') {
        await merge(oldUserID);
        getMy();
        Tools.toast('登陆成功'.tr);
        /// 动态更新用户
        var info = Auth.firebaseUserInfo;
        email.value = info!.email!;
        isEmailVerified.value = info.emailVerified;

        /// 动态更新avatar头像
        var photo = info.photoURL;
        if (photo != null) {
          avatar.value = photo;
        }
      }
    });
    Loading.hide();
  }

  /// 注册
  register() async {
    String? oldUserID = Auth().currentUser?.uid;
    await Get.toNamed(Api.register)?.then((value) async {
      log('注册成功返回，已经登陆 = $value');
      if (value == 'RegisterLoginSuccess') {
        bool isMerge = await merge(oldUserID);
        if(!isMerge){
          Tools.toast('账户合并失败'.tr, type: 'error');
        }
        getMy();
        /// 动态更新登陆显示用户名
        Tools.toast('注册成功'.tr);
        var info = Auth.firebaseUserInfo;
        email.value = info!.email!;
        isEmailVerified.value = info.emailVerified;

        /// 动态更新avatar头像
        var photo = info.photoURL;
        if (photo != null) {
          avatar.value = photo;
        }
      }
    });
    Loading.hide();
  }

  /// 合并账户
  Future<bool> merge(String? oldUserID) async {
    if(oldUserID == null){
      Tools.toast('本地账户登陆异常'.tr, type: 'info');
      return false;
    }
    final dialog = await showOkCancelAlertDialog(
      context: Get.context!,
      message: '是否与本地账号进行合并'.tr,
      isDestructiveAction: true,
      barrierDismissible: false
    );
    if (dialog == OkCancelResult.ok){
      Loading.show(title: '合并账户'.tr);
      try{
        //String oldUserId = Auth().current
        return await HttpUtils.post(Api.merge, data: {'oldUserId': oldUserID}).then((response){
          if(response['error_code'] == 0){
            return true;
          }
          return true;
        }).catchError((e){
          return false;
        });
      } on DioError catch (e){
        return false;
      }
    }else{
      Loading.show(title: '正在登陆'.tr);
    }
    return true;
  }

  /// 邮箱认证
  emailVerified() async {
    if (email.isEmpty){
      Tools.toast('邮箱地址不能为空'.tr, type: 'error');
      return;
    }
    final dialog = await showOkCancelAlertDialog(
      context: Get.context!,
      title: '邮箱验证'.tr,
      message: '将发送验证邮件到'.tr + '\n'+ email.value,
      isDestructiveAction: true,
    );
    if (dialog == OkCancelResult.ok) {
      if(Auth().sendEmail(email.value)){
        Tools.toast('验证邮件发送成功'.tr);
      }else{
        Tools.toast('邮件已经发送,如果没有,请查看垃圾邮箱,请勿频繁发送'.tr, type: 'info');
      }
    }
  }

  /// 升级
  void updateApp() async {
    if (isUpdate.isTrue && appStoreUrl != null) {

      if (await canLaunchUrl(Uri.parse(appStoreUrl!))) {
        HomeController.appSwitch = 'dialog';
        try {
          await launchUrl(Uri.parse(appStoreUrl!));
        } catch (e) {
          log('跳转应用市场失败');
        }
      }

    }
  }

}
