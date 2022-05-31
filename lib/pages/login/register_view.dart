import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import '../../Routes.dart';
import '../../pages/login/register_controller.dart';
import '../../common/auth.dart';
import '../../utils/config.dart';
import 'package:get/get.dart';
import '../../utils/tools.dart';
import '../../widget/loading_button.dart';
import 'other/theme.dart';

class RegisterView extends GetView<RegisterController> {
  RegisterView({Key? key}) : super(key: key);
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.title),
      ),
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 42.0, 24.0, 0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '注册新账号'.tr,
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
                  height: 42,
                ),
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.always,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: textWhiteGrey,
                          borderRadius: BorderRadius.circular(14.0),
                        ),

                        /// 用户输入框
                        child: TextFormField(
                          controller: controller.emailTextForm,
                          decoration: InputDecoration(
                            hintText: '电子邮箱'.tr,
                            hintStyle: heading6.copyWith(color: textGrey),
                            border: const OutlineInputBorder(
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value!.trim().length < 5) {
                              return "不能少于6位字符".tr;
                            }

                            if (!Tools.isEmail(value)) {
                              return '用户名必须为电子邮箱'.tr;
                            }

                            return null;
                          },
                        ),
                      ),
/*                      const SizedBox(
                        height: 24,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: textWhiteGrey,
                          borderRadius: BorderRadius.circular(14.0),
                        ),

                        /// 验证码输入框
                        child: TextFormField(
                          controller: controller.codeTextForm,
                          decoration: InputDecoration(
                            hintText: '验证码'.tr,
                            hintStyle: heading6.copyWith(color: textGrey),
                            border: const OutlineInputBorder(
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Obx(() {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 12.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        String email = controller.emailTextForm.text.trim();
                                        if (email == '') {
                                          Tools.toast('用户名不能为空'.tr, type: 'error');
                                          return;
                                        }
                                        controller.startCountDownTime();
                                      },
                                      child: Text(
                                        controller.countDownTitle.value,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff636363)),
                                      ),
                                    ),
                                  );
                                })
                              ],
                            ),
                          ),
                          validator: (value) {
                            if (value!.trim().length < 5) {
                              return "不能少于6位字符".tr;
                            }
                            return null;
                          },
                        ),
                      ),*/
                      const SizedBox(
                        height: 24,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: textWhiteGrey,
                          borderRadius: BorderRadius.circular(14.0),
                        ),

                        /// 密码输入框
                        child: Obx(() {
                          return TextFormField(
                            controller: controller.passwordTextForm,
                            obscureText: controller.passwordVisible.value,
                            validator: (value) {
                              return value!.trim().length > 5 ? null : "不能少于6位字符".tr;
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
                      const SizedBox(
                        height: 24,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: textWhiteGrey,
                          borderRadius: BorderRadius.circular(14.0),
                        ),

                        /// 确认密码输入框
                        child: Obx(() {
                          return TextFormField(
                            controller: controller.password2TextForm,
                            obscureText: controller.passwordVisible.value,
                            validator: (value) {
                              if (value!.trim().length < 6) {
                                return "不能少于6位字符".tr;
                              }

                              if (value != controller.passwordTextForm.text.trim()) {
                                return '两次密码必须相同'.tr;
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: '重复密码'.tr,
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
                  height: 12,
                ),

                /// 密码可见按扭
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Obx(() {
                      return GestureDetector(
                        onTap: () {
                          controller.toggleIsChecked();
                        },
                        child: Container(
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
                      );
                    }),
                    const SizedBox(
                      width: 12,
                    ),
                    /// 同意签名
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AutoSizeText(
                            '创建账号即表示同意我们的'.tr,
                            style: regular16pt.copyWith(color: textGrey),
                            maxLines: 1,
                          ),
                          Text(
                            '隐私条款'.tr,
                            style: regular16pt.copyWith(color: const Color(PRIMARYCOLOR),fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 50,
                ),

                /// 注册按扭
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: LoadingButton(
                    icon: PhosphorIcons.user_plus,
                    title: '注册账号'.tr,
                    color: const Color(PRIMARYCOLOR),
                    onPress: () async {
                      if (controller.isChecked.isFalse) {
                        Tools.toast('请选择同意'.tr, type: 'info');
                        return;
                      }

                      /// 验证表单
                      if (_formKey.currentState!.validate()) {
                        var isRegister = await Auth()
                            .register(controller.emailTextForm.text.trim(), controller.passwordTextForm.text.trim());
                        if (isRegister == true) {
                          log('注册成功,返回个人中心 = $isRegister');
                          Get.back(result: 'RegisterLoginSuccess');
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),

                /// 切换登陆按扭
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "已经有一个账号".tr,
                      style: regular16pt.copyWith(color: textGrey),
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.offNamed(Routes.login);
                      },
                      child: Text(
                        '登陆'.tr,
                        style: regular16pt.copyWith(color: const Color(PRIMARYCOLOR)),
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
