import 'dart:async';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../Routes.dart';
import '../../common/admob.dart';
import '../../common/notice_bar.dart';
import '../../pages/email/email_controller.dart';
import '../../utils/config.dart';
import '../../utils/tools.dart';
import '../../widget/loading_button.dart';
import '../../widget/widget.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:get/get.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';

class EmailView extends GetView<EmailController> {
  //form表单提交
  final GlobalKey<FormState> createEmailForm = GlobalKey<FormState>();
  final EasyRefreshController _refreshController = EasyRefreshController();
  static const _insets = 16.0;

  double get _adWidth => MediaQuery.of(Get.context!).size.width - (2 * _insets);

  EmailView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.title, semanticsLabel: controller.title,),
      ),
      body: Column(
        children: [
/*          getNotice(),
          email(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: button(context),
          ),
          Obx(()=>ad()),
          const SizedBox(height: 8,),*/
          Expanded(
            child: list(context),
          ),
        ],
      ),
    );
  }

  ///EMAIL地址
  Widget email() {
    return Padding(
      padding: const EdgeInsets.only(left: 15.0, top: 15.0, right: 15.0, bottom: 15.0),
      child: Center(
        child: Obx(
          (){
            var currentEmailSite = controller.currentEmailSite.value;

            if(currentEmailSite.isEmpty){
              currentEmailSite = '请选择邮箱后坠'.tr;
            }
            String emailSite = controller.currentEmailUser.toString() + currentEmailSite;
            return AutoSizeText(
              emailSite,
              style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              maxLines: 1,
              semanticsLabel: emailSite,
            );
          },
        ),
      ),
    );
  }

  ///按钮组
  Widget button(context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
                child: LoadingButton(
              onPress: () async {
                String? email = controller.emailAddress;
                if (email == null) {
                  Tools.toast("请先申请邮箱地址".tr, type: 'info');
                  createUser();
                } else {
                  FlutterClipboard.copy(email).then((value) {
                    Tools.toast(email + "复制成功".tr);
                  });
                }
              },
              title: '复制'.tr,
              icon: PhosphorIcons.copy,
            )),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                  onPressed: () {
                    if (controller.emailAddress != null) {
                      Tools.toast("【${controller.emailAddress}】" + "正在使用中,如需更换,请先销毁".tr, type: 'info');
                    } else {
                      createUser();
                    }
                  },
                  icon: const Icon(PhosphorIcons.at),
                  label: Text("创建".tr, semanticsLabel: '创建'.tr,)),
            )
          ],
        ),
        Container(
          transform: Matrix4.translationValues(0, -5, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Obx((){
                  return LoadingButton(
                    icon: PhosphorIcons.arrows_counter_clockwise,
                    title: controller.autoButton.value,
                    color: Colors.green,
                    onPress: () async {
                      await _requestEmailList(from: 'auto');
                    },
                  );
                }),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: LoadingButton(
                  icon: PhosphorIcons.trash,
                  title: '删除'.tr,
                  color: Colors.red,
                  onPress: () async {
                    if (controller.emailAddress == null) {
                      Tools.toast('邮箱地址不存在,请先创建'.tr, type: 'info');
                      createUser();
                      return false;
                    }
                    final dialog = await showOkCancelAlertDialog(
                      context: context,
                      title: '确定删除'.tr,
                      message: '删除后,将永远无法找回'.tr,
                      isDestructiveAction: true,
                    );
                    if (dialog == OkCancelResult.ok) {
                      await controller.deleteEmail();
                    }
                  },
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  /// 广告
  Widget ad() {
    if (controller.isBannerShow.isTrue && Admob().bannerInlineLeaderboardAdSize != null) {
      return Center(
            child: Container(
              color: Colors.transparent,
              width: _adWidth,
              height: Admob().bannerInlineLeaderboardAdSize!.height.toDouble(),
              child: AdWidget(ad: Admob().bannerInlineLeaderboardAd!),
            ),
          );
    } else {
      return Container();
    }
  }

  ///邮件展示
  Widget list(context) {
    return Obx((){
      return EasyRefresh.custom(
        onRefresh: () async {
          await _requestEmailList(from: 'refresh');
          _refreshController.finishRefresh(success: true);
        },
        //onLoad: _onLoad,

        slivers: [
/*          SliverAppBar(
            title: Text('111'),
            floating: true,
            snap: true,
          ),*/
          SliverToBoxAdapter(
            child: Column(
              children: <Widget>[
                getNotice(),
                email(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: button(context),
                ),
                ad(),
                const SizedBox(height: 8,),
              ],
            ),
          ),
          Obx(() {
            if (controller.isShowEmpty.isFalse) {
              return SliverToBoxAdapter(
                child: emptyPageWidget(image: 'noEmail', title: '列表为空'.tr, subTitle: '尝试下拉刷新'.tr),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return emailListItemBuilder(context, index);
              }, childCount: controller.emailList.length),
            );
          }),
        ],
      );
    });
  }

  ///邮件列表 Widget
  Widget emailListItemBuilder(BuildContext context, int index) {
    String lastTime = Tools.timeHandler(controller.emailList[index]['time']);
    return InkWell(
      onTap: () => Get.toNamed(Routes.emailDetail, arguments: controller.emailList[index]),
      child: Card(
          elevation: 8.0, //设置阴影
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0))), //设置圆角
          child: ListTile(
            leading: const Icon(
              PhosphorIcons.user_circle,
              size: 50,
            ),
            title: Text(
              controller.emailList[index]['subject'],
              overflow: TextOverflow.ellipsis,
              semanticsLabel: controller.emailList[index]['subject'],
            ),
            isThreeLine: true,
            trailing: const Padding(
              padding: EdgeInsets.only(top: 15.0),
              child: Icon(PhosphorIcons.caret_right),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(controller.emailList[index]['from'], semanticsLabel: controller.emailList[index]['from'],),
                Text(lastTime, semanticsLabel: lastTime,),
              ],
            ),
          )),
    );
  }

  ///请求邮件列表
  Future<void> _requestEmailList({String from = 'auto'}) async {

    if (controller.emailAddress == null) {
      createUser();
    } else {

      if(from == 'auto' && controller.autoRequestRunning.isFalse){
        // 自动刷新
        controller.autoRequestRunning.value = true;
        await controller.autoEmailList();
      }

      if(from == 'refresh' && controller.autoRequestRunning.isFalse){
        // 手动请求一次
        await controller.fetchEmailList();
      }

    }

    /// 切换banner广告
/*    controller.isBannerShow.value = false;
    await Future.delayed(const Duration(milliseconds: 10));
    controller.isBannerShow.value = true;*/
  }

  ///创建邮箱
  Widget _createUser() {
    BuildContext context = Get.context!;
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Form(
        key: createEmailForm,
        child: Column(
          children: [
            TextFormField(
              ///Username输入框
              onChanged: (text) {
                controller.currentEmailUser(text);
              },
              validator: (value) {
                return value!.trim().length > 6 ? null : "不能少于6位字符".tr;
              },
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Username'),
            ),
            GetBuilder(
                init: EmailController(),
                id: 'emailSite',
                builder: (EmailController controller) {
                  return Padding(
                    ///site下拉列表
                    padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
                    child: DropdownButtonFormField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        value: controller.currentEmailSite.isEmpty ? 'loading' : controller.currentEmailSite.value,
                        items: controller.dropDownItem,
                        onChanged: (value) {
                          //设置当前邮箱后坠
                          controller.setCurrentItem(value);
                        }),
                  );
                }),
            const SizedBox(height: 20,),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: LoadingButton(
                icon: PhosphorIcons.shuffle,
                title: '随机注册邮箱'.tr,
                color: const Color(PRIMARYCOLOR),
                onPress: () async {
                  if(controller.currentEmailSite.value.isEmpty){
                    controller.fetchMailList();
                    return;
                  }
                  await controller.fetchEmailAddress().then((value) {
                    //获取成功后，关闭bottomSheet
                    Navigator.pop(context);
                  }).catchError((error) {
                    Tools.toast('请求失败'.tr, type: 'error');
                  });
                },
              ),
            ),
            const SizedBox(height: 10,),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: LoadingButton(
                icon: PhosphorIcons.pencil,
                title: '指定用户名注册'.tr,
                color: Colors.green,
                onPress: () async {
                  if(controller.currentEmailSite.value.isEmpty){
                    controller.fetchMailList();
                    return;
                  }

                  if ((createEmailForm.currentState as FormState).validate()) {
                    //校验通过
                    var result = await controller.fetchEmailAddress(type: 'user');
                    if (result) {
                      Navigator.pop(context);
                    } else {
                      Tools.toast('请求失败'.tr, type: 'error');
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  ///注册邮箱弹窗
  void createUser() {
    controller.fetchMailList();
    Get.bottomSheet(
      Container(
        height: 390,
        color: Colors.white,
        child: _createUser(),
      ),
      isScrollControlled: true,
    );
  }
}
