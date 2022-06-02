import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../pages/country/country_view.dart';
import '../../pages/email/email_view.dart';
import '../../pages/home/home_controller.dart';
import '../../pages/my/my_view.dart';
import '../../pages/phone/phone_view.dart';
import '../../utils/api.dart';
import '../../utils/config.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:get/get.dart';
import '../../utils/tools.dart';
import 'package:upgrader/upgrader.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.put(HomeController());

    final versionUrl = Api.baseUrl + 'version.xml';
    final cfg = AppcastConfiguration(url: versionUrl, supportedOS: ['android']);

    return WillPopScope(
      onWillPop: () async {
        if (controller.lastPopTime == null || DateTime.now().difference(controller.lastPopTime!) > const Duration(seconds: 2)) {
          // 存储当前按下back键的时间
          controller.lastPopTime = DateTime.now();
          // toast
          Tools.toast("再按一次退出app".tr, type: 'info');
          return false;
        } else {
          controller.lastPopTime = DateTime.now();
          // 退出app
          await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
          return true;
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // 自动更新
              Obx(() => controller.isUpgraderShow.isFalse ? Container() : UpgradeAlert(
                upgrader: controller.updateInfo,
              )),
              Expanded(
                child: PageView(
                  controller: controller.pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [const PhoneView(), const CountryView(), EmailView(), const MyView()],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Obx((){
          return BottomNavigationBar(
              currentIndex: controller.curPage.value,
              selectedItemColor: const Color(PRIMARYCOLOR),
              type: BottomNavigationBarType.fixed,
              unselectedFontSize: 12,
              selectedFontSize: 12,
              onTap: (int idx) {
                //跳转到指定页面
                controller.pageController.jumpToPage(idx);
                controller.curPage.value = idx;
              },
              items: <BottomNavigationBarItem>[

                BottomNavigationBarItem(
                    icon: Badge(
                      badgeContent: Text(
                        controller.phoneBadgeCount.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                      child: Icon(PhosphorIcons.device_mobile, color: controller.defaultColor),
                      showBadge: controller.phoneBadgeCount > 0 ? true : false,
                    ),
                    activeIcon: Badge(
                      badgeContent: Text(controller.phoneBadgeCount.toString(), style: const TextStyle(color: Colors.white)),
                      child: Icon(PhosphorIcons.device_mobile_bold, color: controller.activeColor),
                      showBadge: controller.phoneBadgeCount > 0 ? true : false,
                    ),
                    label: '号码'.tr),
                BottomNavigationBarItem(
                    icon: Icon(PhosphorIcons.globe_hemisphere_east, color: controller.defaultColor),
                    activeIcon: Icon(PhosphorIcons.globe_hemisphere_west_bold, color: controller.activeColor),
                    label: '国家'.tr),
                BottomNavigationBarItem(
                    icon: Icon(PhosphorIcons.envelope_simple, color: controller.defaultColor),
                    activeIcon: Icon(PhosphorIcons.envelope_simple_open_bold, color: controller.activeColor),
                    label: '临时邮箱'.tr),
                BottomNavigationBarItem(
                    icon: Badge(
                        shape: BadgeShape.circle,
                        position: BadgePosition.topEnd(top: -3, end: -8),
                        padding: const EdgeInsets.only(left: 4.0,right: 6.0,top: 4.0,bottom: 4.0),
                        showBadge: controller.isMyBadgeShow.isTrue ? true : false,
                        child: Icon(PhosphorIcons.user_circle, color: controller.defaultColor)),
                    activeIcon: Badge(
                        shape: BadgeShape.circle,
                        position: BadgePosition.topEnd(top: -3, end: -8),
                        padding: const EdgeInsets.only(left: 4.0,right: 6.0,top: 4.0,bottom: 4.0),
                        showBadge: controller.isMyBadgeShow.isTrue ? true : false,
                        child: Icon(PhosphorIcons.user_circle_bold, color: controller.activeColor)),
                    label: '我的'.tr),
              ]);
        }),
      ),
    );
  }
}
