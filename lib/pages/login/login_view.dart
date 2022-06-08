import 'package:ReceiveSMS/common/loading.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import '../../Routes.dart';
import '../../common/auth.dart';
import '../../common/local_storage.dart';
import '../../pages/login/login_controller.dart';
import '../../utils/config.dart';
import 'package:get/get.dart';
import '../../utils/tools.dart';
import '../../widget/loading_button.dart';
import 'other/theme.dart';

class LoginView extends GetView<LoginController> {
  LoginView({Key? key}) : super(key: key);
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {

          LocalStorage().setIncr('ttt').then((value) => log(value));

        },
        tooltip: 'Increment',
        child: const Icon(Icons.refresh),
      ),
      appBar: AppBar(
        title: Text(controller.title),
      ),
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 40.0, 24.0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '登陆到您的账户'.tr,
                      style: heading2.copyWith(color: textBlack),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Image.asset(
                      'assets/images/accent.png',
                      width: 99,
                      height: 4,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 48,
                ),

                /// 表单
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.always,
                  child: Column(
                    children: [
                      /// 用户输入框
                      Container(
                        decoration: BoxDecoration(
                          color: textWhiteGrey,
                          borderRadius: BorderRadius.circular(14.0),
                        ),
                        child: Obx(() {
                          controller.emailTextForm = TextEditingController(text: controller.username.value);
                          return TextFormField(
                            controller: controller.emailTextForm,
                            validator: (value) {
                              if (!Tools.isEmail(value!)) {
                                return '用户名必须为电子邮箱'.tr;
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: '电子邮箱'.tr,
                              hintStyle: heading6.copyWith(color: textGrey),
                              border: const OutlineInputBorder(
                                borderSide: BorderSide.none,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(
                        height: 32,
                      ),

                      /// 密码输入框
                      Container(
                        decoration: BoxDecoration(
                          color: textWhiteGrey,
                          borderRadius: BorderRadius.circular(14.0),
                        ),
                        child: Obx(() {
                          controller.passwordTextForm = TextEditingController(text: controller.password.value);
                          return TextFormField(
                            controller: controller.passwordTextForm,
                            obscureText: controller.passwordVisible.value,
                            validator: (value) {
                              if (value!.trim().length < 6) {
                                return "不能少于6位字符".tr;
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: '密码'.tr,
                              hintStyle: heading6.copyWith(color: textGrey),
                              suffixIcon: IconButton(
                                color: textGrey,
                                splashRadius: 1,
                                icon: Icon(controller.passwordVisible.value
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                                onPressed: () {
                                  controller.togglePassword();
                                },
                              ),
                              border: const OutlineInputBorder(
                                borderSide: BorderSide.none,
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),

                /// 显示密码按扭
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(() {
                      return GestureDetector(
                        onTap: () {
                          controller.toggleIsChecked();
                        },
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: controller.isChecked.value ? const Color(PRIMARYCOLOR) : Colors.transparent,
                                borderRadius: BorderRadius.circular(4.0),
                                border: controller.isChecked.value ? null : Border.all(color: textGrey, width: 1.5),
                              ),
                              width: 20,
                              height: 20,
                              child: controller.isChecked.value
                                  ? const Icon(
                                      Icons.check,
                                      size: 20,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Text('记住密码'.tr, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                          ],
                        ),
                      );
                    }),
                    GestureDetector(
                        onTap: () async {
                          String email = controller.emailTextForm.text.trim();
                          if (email.isEmpty){
                            Tools.toast('邮箱地址不能为空'.tr, type: 'error');
                            return;
                          }
                          final dialog = await showOkCancelAlertDialog(
                            context: context,
                            title: '找回密码'.tr,
                            message: '将发送更改密码邮件到'.tr + '\n'+ email,
                            isDestructiveAction: true,
                          );
                          if (dialog == OkCancelResult.ok) {
                            if(Auth().sendEmail(email)){
                              Tools.toast('更改密码邮件发送成功'.tr);
                            }else{
                              Tools.toast('邮件已经发送,如果没有,请查看垃圾邮箱,请勿频繁发送'.tr, type: 'info');
                            }
                          }
                        },
                        child: Text('忘记密码'.tr, style: const TextStyle(color: Colors.grey, fontSize: 14))),
                  ],
                ),
                const SizedBox(
                  height: 50,
                ),

                /// 登陆按扭
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: LoadingButton(
                    icon: PhosphorIcons.envelope_light,
                    title: '电子邮箱登陆'.tr,
                    color: const Color(PRIMARYCOLOR),
                    onPress: () async {
                      if (_formKey.currentState!.validate()) {
                        await controller.login(
                            controller.emailTextForm.text.trim(), controller.passwordTextForm.text.trim());
                      }
                    },
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
                Center(
                  child: Text(
                    'OR',
                    style: heading6.copyWith(color: textGrey),
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),

                /// google登陆
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: LoadingButton(
                    icon: PhosphorIcons.google_logo_bold,
                    title: 'Google登陆'.tr,
                    color: Colors.red,
                    onPress: () async {
                      Loading.show(title: '正在登陆Google'.tr);
                      await Auth().googleLogin().then((value) {
                        //log('接收google登陆返回值 = $value');
                        if (value == true) {
                          //log('google登陆返回成功');
                          Get.back(result: 'LoginSuccess');
                        } else {
                          Tools.toast(value ?? 'Google登陆失败,请检查网络是否连接'.tr, type: 'error', time: 5);
                        }
                      });
                      Loading.hide();
                    },
                  ),
                ),
                const SizedBox(
                  height: 50,
                ),

                /// 跳转注册按扭
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "没有账号".tr,
                      style: regular16pt.copyWith(color: textGrey, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () {
                        //跳转到register
                        Get.offNamed(Routes.register);
                      },
                      child: Text(
                        '注册'.tr,
                        style: regular16pt.copyWith(color: const Color(PRIMARYCOLOR), fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
