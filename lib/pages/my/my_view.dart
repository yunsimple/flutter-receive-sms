import 'package:ReceiveSMS/common/loading.dart';
import 'package:ReceiveSMS/common/remote_config.dart';
import 'package:ReceiveSMS/utils/api.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:badges/badges.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:get/get.dart';
import '../../Routes.dart';
import '../../common/auth.dart';
import '../../common/language.dart';
import '../../common/local_storage.dart';
import '../../common/notice_bar.dart';
import '../../common/secure_storage.dart';
import '../../utils/tools.dart';
import 'my_controller.dart';
import 'package:babstrap_settings_screen/babstrap_settings_screen.dart';
import 'dart:ui' as ui;
import 'package:restart_app/restart_app.dart';

class MyView extends GetView<MyController> {
  const MyView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
/*      floatingActionButton: FloatingActionButton(
        onPressed: () async {

          log(RemoteConfigApi().getString('rk'));

        },
        tooltip: 'Increment',
        child: const Icon(Icons.refresh),
      ),*/
      appBar: AppBar(
        title: Text(controller.title),
        //centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [getNotice(), Expanded(child: settingList(context))],
      ),
    );
  }

  settingList(context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xffF1F0F0)),
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: ListView(
          children: [
            const SizedBox(
              height: 20,
            ),
            // user card
            userInfoWidget(),
            const SizedBox(
              height: 20,
            ),
            Obx(() {
              return SettingsGroup(
                items: [
                  SettingsItem(
                    onTap: () async {
                      Get.toNamed(
                        Routes.phoneList + '?countryID=vip&title=' + 'VIP??????'.tr,
                      );
                    },
                    icons: PhosphorIcons.crown_simple_light,
                    iconStyle: IconStyle(
                      iconsColor: Colors.white,
                      withBackground: true,
                      backgroundColor: Colors.amberAccent[700],
                    ),
                    title: 'VIP??????'.tr,
                    subtitle: '??????????????????'.tr,
                    trailing: controller.phoneCount['vipPhoneCount']! > 0
                        ? Text(
                            controller.phoneCount['vipPhoneCount'].toString(),
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          )
                        : const Icon(
                            PhosphorIcons.caret_right_bold,
                            size: 20,
                          ),
                  ),
                  SettingsItem(
                    onTap: () {
                      Get.toNamed(
                        Routes.phoneList + '?countryID=upcoming&title=' + '????????????'.tr,
                      );
                    },
                    trailing: controller.phoneCount['upcomingPhoneCount']! > 0
                        ? Text(
                            controller.phoneCount['upcomingPhoneCount'].toString(),
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          )
                        : const Icon(
                            PhosphorIcons.caret_right_bold,
                            size: 20,
                          ),
                    icons: PhosphorIcons.lightning_light,
                    iconStyle: IconStyle(
                      iconsColor: Colors.white,
                      withBackground: true,
                      backgroundColor: Colors.redAccent[700],
                    ),
                    title: '????????????'.tr,

                    /// todo????????????????????????API??????
                    subtitle: '????????????'.tr +
                        ': ' +
                        Tools.getYmd(ymd: 'ymdh', timestamp: controller.myInfo['upcomingTime'] ??= 0, line: '-'),
                  ),
                  SettingsItem(
                    onTap: () async {
                      Get.toNamed(
                        Routes.phoneList + '?countryID=favorites&title=' + '????????????'.tr,
                      );
                    },
                    icons: PhosphorIcons.bookmark_light,
                    iconStyle: IconStyle(),
                    title: '??????'.tr,
                    subtitle: '????????????????????????'.tr,
                    trailing: controller.phoneCount['favoritesPhoneCount']! > 0
                        ? Text(controller.phoneCount['favoritesPhoneCount'].toString())
                        : const Icon(
                            PhosphorIcons.caret_right_bold,
                            size: 20,
                          ),
                  ),
                ],
              );
            }),

            Obx(() {
              return SettingsGroup(
                items: [
                  SettingsItem(
                    onTap: () {
                      log('????????????');
                    },
                    icons: PhosphorIcons.globe_light,
                    iconStyle: IconStyle(
                      backgroundColor: Colors.indigo,
                    ),
                    title: '????????????'.tr,
                    subtitle: controller.currentLanguage,
                    trailing: DropdownButton(
                      value: controller.currentLanguage,
                      underline: Container(),
                      onChanged: (value) {
                        String lang = '';
                        String country = '';
                        if (value == 'English') {
                          lang = 'en';
                          country = 'US';
                          LocalStorage().setJSON('language', {'languageCode': lang, 'countryCode': country});
                        }
                        if (value == '????????????') {
                          lang = 'zh';
                          country = 'CN';
                          LocalStorage().setJSON('language', {'languageCode': lang, 'countryCode': country});
                        }
                        if (value == 'Deutsch') {
                          lang = 'de';
                          country = 'DE';
                          LocalStorage().setJSON('language', {'languageCode': lang, 'countryCode': country});
                        }
                        if (value == 'Portugu??s') {
                          lang = 'pt';
                          country = 'BR';
                          LocalStorage().setJSON('language', {'languageCode': lang, 'countryCode': country});
                        }
                        if (value == 'System') {
                          var system = ui.window.locale;
                          lang = system.languageCode;
                          country = system.countryCode ?? 'US';
                          LocalStorage().remove('language');
                        }
                        controller.currentLanguage = value as String;
                        LanguageChangeController().changeLanguage(lang, country);
                      },
                      items: <String>['System', 'English', 'Deutsch', 'Portugu??s', '????????????']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
/*                SettingsItem(
                  onTap: () {},
                  icons: PhosphorIcons.moon_light,
                  iconStyle: IconStyle(
                    iconsColor: Colors.white,
                    withBackground: true,
                    backgroundColor: Colors.indigoAccent,
                  ),
                  title: '????????????'.tr,
                  subtitle: '??????'.tr,
                  trailing: Switch.adaptive(
                    value: false,
                    onChanged: (value) {},
                  ),
                ),*/
                  SettingsItem(
                      onTap: () async {
                        // ??????store storage????????????
                        // ??????refreshToken accessToken
                        final dialog = await showOkCancelAlertDialog(
                          context: context,
                          message: '???????????????,??????????????????APP'.tr,
                          isDestructiveAction: true,
                        );
                        if (dialog == OkCancelResult.ok) {
                          await DioCacheManager(CacheConfig(baseUrl: Api.baseUrl)).clearAll();
                          SecureStorage().del(deleteAll: true).then((value) async {
                            //Tools.toast('??????????????????'.tr);
                            await RemoteConfigApi().fetchAndActivate(minimumFetchInterval: true);
                            Restart.restartApp();
                          });
                        }
                      },
                      icons: PhosphorIcons.recycle_light,
                      iconStyle: IconStyle(
                        backgroundColor: Colors.green,
                      ),
                      title: '????????????'.tr,
                      subtitle: "???????????????????????????,???????????????".tr,
                      trailing: const Icon(
                        PhosphorIcons.caret_right_bold,
                        size: 20,
                      )),
                  SettingsItem(
                      onTap: () async {
                        controller.updateApp();
                      },
                      icons: PhosphorIcons.git_branch_light,
                      iconStyle: IconStyle(
                        backgroundColor: Colors.greenAccent,
                      ),
                      title: '??????'.tr,
                      subtitle: controller.isUpdate.isFalse
                          ? controller.currentVersion.value
                          : '${controller.currentVersion} -> ${controller.storeVersion}',
                      trailing: controller.isUpdate.isTrue
                          ? Badge(
                              shape: BadgeShape.circle,
                              showBadge: true,
                              padding: const EdgeInsets.only(left: 4.0, right: 18.0, top: 4.0, bottom: 4.0),
                            )
                          : const SizedBox()),
                ],
              );
            }),
            // ??????
            SettingsGroup(
              items: [
                SettingsItem(
                  onTap: () async {
                    if (controller.email.isEmpty) return;
                    final dialog = await showOkCancelAlertDialog(
                      context: context,
                      title: '????????????'.tr,
                      message: '?????????,?????????????????????????????????'.tr,
                      isDestructiveAction: true,
                    );
                    if (dialog == OkCancelResult.ok) {
                      Loading.show(title: '????????????'.tr);
                      await Auth().loginOut().then((value) {
                        controller.email.value = '';
                        controller.avatar.value = '';
                        controller.userInfo.value = {};
                        Tools.toast('??????????????????'.tr, type: 'info');
                      });
                      Loading.hide();
                    }
                  },
                  icons: PhosphorIcons.sign_out_light,
                  iconStyle: IconStyle(
                    backgroundColor: Colors.red,
                  ),
                  title: '??????'.tr,
                  subtitle: "????????????".tr,
                  trailing: const Icon(
                    PhosphorIcons.caret_right_bold,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget userInfoWidget() {
    Widget userInfoWidget = Container(
      decoration: BoxDecoration(
        color: const Color(0xffE4BF50),
        borderRadius: BorderRadius.circular(16),
      ),
      height: 120,
      child: Padding(
        padding: const EdgeInsets.only(top: 25.0, bottom: 25.0, left: 15.0, right: 15.0),
        child: Row(
          children: [
            SizedBox(
              height: 80,
              width: 70,
              child: ClipOval(
                child: Obx(() {
                  return controller.avatar.isEmpty
                      ? Image.asset(
                          'assets/images/avatar.png',
                        )
                      : CachedNetworkImage(
                          fit: BoxFit.cover,
                          imageUrl: controller.avatar.value, //'https://s1.ax1x.com/2022/05/10/OY76r6.jpg',
                          errorWidget: (context, url, error) => const Icon(
                            PhosphorIcons.user_circle_light,
                            size: 75,
                            color: Colors.black45,
                          ),
                        );
                }),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Obx(() {
              return controller.email.isNotEmpty ? infoWidget() : loginWidget();
            }),
          ],
        ),
      ),
    );
    return userInfoWidget;
  }

  loginWidget() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 5.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    controller.login();
                  },
                  child: Text(
                    '??????'.tr + ' /',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.black54,
                    ),
                    maxLines: 1,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    controller.register();
                  },
                  child: Text(
                    ' ' + '??????'.tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.black54,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            Expanded(
              child: AutoSizeText(
                '?????????????????????????????????'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black45,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  infoWidget() {
    //User user = controller.userInfo.value as User;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 5.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AutoSizeText(
              controller.email.value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black54,
              ),
              maxLines: 1,
            ),
            AutoSizeText(
              controller.userInfo.isEmpty ? '????????????'.tr : '??????'.tr + ':${controller.userInfo['coins'].toString()}',
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black45,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
