import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:badges/badges.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../Routes.dart';
import '../../common/admob.dart';
import '../../common/remote_config.dart';
import '../../pages/phone/phone_detail_controller.dart';
import '../../utils/api.dart';
import '../../utils/tools.dart';
import '../../widget/loading_button.dart';
import '../../widget/widget.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/config.dart';
import 'package:slide_countdown/slide_countdown.dart';

class PhoneDetailView extends GetView<PhoneDetailController> {
  const PhoneDetailView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // remote config 远程获取原生广告下标，如果放在controller，跟easyFresh有点不兼容
    Map messageConfig = RemoteConfigApi().getJson('message');
    controller.isLoad = messageConfig['isLoad'];
    String index = messageConfig['adMessageNativeIndex'];
    controller.insertIndex = Tools.listStringTransitionInt(index.split(','));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.currentPhoneInfo['phone_num'],
          semanticsLabel: controller.currentPhoneInfo['phone_num'],
        ),
        elevation: 0,
      ),
      body: EasyRefresh.custom(
        emptyWidget: null,
        onRefresh: _onRefresh,
        onLoad: controller.isLoad == false
            ? null
            : () async {
                _onLoad();
              },
        slivers: [
/*          SliverAppBar(
            title: Text(controller.phone),
            floating: true,
            snap: true,
          ),*/
          SliverToBoxAdapter(
            child: Column(
              children: <Widget>[_card(), _button()],
            ),
          ),
          Obx(() {
            if (controller.showEmpty.isTrue) {
              return SliverToBoxAdapter(
                child: emptyPageWidget(),
              );
            }
            if (controller.isLoading.isTrue) {
              return SliverToBoxAdapter(
                child: Center(
                  child: Column(
                    children: const [
                      SizedBox(
                        height: 50,
                      ),
                      CircularProgressIndicator(),
                    ],
                  ),
                ),
              );
            } else {
              return _selectTypeMessage();
            }
          }),
        ],
        scrollController: controller.scrollController,
      ),
      floatingActionButton: Obx(() {
        return controller.isShowFloatBtn.isFalse
            ? const SizedBox()
            : FloatingActionButton(
                onPressed: () async {
                  controller.scrollController.animateTo(
                    .0,
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.ease,
                  );
                },
                tooltip: 'Top',
                child: const Icon(PhosphorIcons.arrow_fat_lines_up_fill),
                mini: true,
              );
      }),

      /// banner底部广告
      bottomNavigationBar: Obx(() {
        return controller.isBannerShow.isTrue && Admob().bannerAnchoredAd != null
            ? Container(
                color: Colors.transparent,
                width: Admob().bannerAnchoredAd!.size.width.toDouble(),
                height: Admob().bannerAnchoredAd!.size.height.toDouble(),
                child: AdWidget(ad: Admob().bannerAnchoredAd!),
              )
            : const SizedBox();
      }),
    );
  }

  _selectTypeMessage() {
    // 根据type，显示不同的widget
    if (controller.numberType.value == 1) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return _message(context, index);
          },
          childCount: controller.messageList.length,
        ),
      );
    } else if (controller.numberType.value == 2) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Column(
            children: [
              Text(
                controller.countdownTitle.value,
                semanticsLabel: controller.countdownTitle.value,
              ),
              const SizedBox(
                height: 10,
              ),
              Center(
                child: SlideCountdownSeparated(
                  duration: Duration(seconds: controller.upcomingSecond),
                  height: 60,
                  width: 60,
                  textStyle: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold),
                  onDone: () {
                    controller.countdownTitle.value = '加载中'.tr + '...';
                    _onRefresh();
                  },
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              controller.isMiddleBannerShow.isTrue ? bannerAd() : Container(),
            ],
          ),
        ),
      );
    } else {
      return SliverToBoxAdapter(
        child: Column(
          children: [
            const SizedBox(
              height: 15,
            ),
            Text(
              '金币数量'.tr + ': ${controller.coins.value}',
              style: const TextStyle(fontWeight: FontWeight.bold),
              semanticsLabel: '金币数量'.tr,
            ),
            const SizedBox(
              height: 15,
            ),
            SizedBox(
              height: 40,
              child: LoadingButton(
                title: '使用号码'.tr + ' (-${controller.price.value})',
                color: Colors.blue[800],
                onPress: () async {
                  bool isBuy = await controller.buyVipNumber();
                  if (isBuy) {
                    _onRefresh();
                  }
                },
                icon: PhosphorIcons.shopping_cart_simple,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Badge(
              shape: BadgeShape.square,
              borderRadius: BorderRadius.circular(2),
              position: BadgePosition.topEnd(top: -12, end: -20),
              padding: const EdgeInsets.all(2),
              badgeColor: Colors.red,
              badgeContent: const Text(
                'hot',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
              child: SizedBox(
                height: 50,
                child: LoadingButton(
                  title: '观看广告获得奖励'.tr + ' (+${controller.rewardCoins})',
                  onPress: () async {
                    // todo 如果中途切换账号，前一个预加载的广告奖励不会记在当在
                    if (Admob().rewardedAd == null) {
                      await Future.delayed(const Duration(seconds: 2));
                    } else {
                      Admob().showRewarded();
                    }
                  },
                  icon: PhosphorIcons.video_camera,
                ),
              ),
            ),
            const SizedBox(
              height: 3,
            ),
            AutoSizeText(
              '仅需支付一次,成功后下次可直接使用'.tr,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(
              height: 20,
            ),
            controller.isMiddleBannerShow.isTrue ? bannerAd() : Container(),
          ],
        ),
      );
    }
  }

  ///顶部card
  _card() {
    String flag = Api.baseUrl + "/static/images/flag/circle/${controller.currentPhoneInfo['country']['bh']}.png";
    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(
        colors: [Color(PRIMARYCOLOR), Color(0xFFffffff)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      )),
      child: Padding(
        padding: const EdgeInsets.only(top: 10.0, bottom: 8.0, left: 6.0, right: 6.0),
        child: SizedBox(
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 20, left: 10, right: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CachedNetworkImage(
                        imageUrl: flag,
                        width: 64,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.currentPhoneInfo['country']['title'] + "号码".tr,
                            style: const TextStyle(fontSize: 16),
                          ),
                          InkWell(
                            onTap: () {
                              FlutterClipboard.copy(controller.currentPhoneInfo['phone_num']).then((value) {
                                Tools.toast("【${controller.currentPhoneInfo['phone_num']}】" + '复制成功'.tr, type: 'info');
                              });
                            },
                            child: Row(
                              children: [
                                Text(
                                  '+${controller.currentPhoneInfo['country']['bh']}',
                                  style: const TextStyle(fontFamily: 'tel', fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Text(
                                  ' ' + controller.currentPhoneInfo['phone_num'],
                                  style: const TextStyle(fontFamily: 'tel', fontWeight: FontWeight.bold, fontSize: 25),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Obx(() {
                                  return controller.isOnline.isTrue
                                      ? const Icon(
                                          Icons.signal_cellular_alt,
                                          color: Colors.green,
                                        )
                                      : const Icon(
                                          Icons.signal_cellular_alt,
                                          color: Colors.red,
                                        );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _remind(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  ///提醒说明
  Widget _remind() {
    return Center(
      child: DefaultTextStyle(
          style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.5, wordSpacing: 1.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 10,
              ),
              Text('下拉页面刷新以获取新消息'.tr),
              Text('新消息将在大约30秒后到达'.tr),
              Text(
                '任何人都可以看到这个号码的消息'.tr,
                style: const TextStyle(color: Colors.red),
              ),
              //Text('为什么接收不到'.tr),
            ],
          )),
    );
  }

  ///button操作区域
  _button() {
    return SizedBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingButton(
            title: '随机号码'.tr,
            icon: PhosphorIcons.shuffle,
            onPress: () async {
              await controller.fetchRandomPhone().then((response) {
                Get.offNamed(
                  Routes.phoneDetail + '?phone=' + response['phone_num'],
                  arguments: response,
                );
              });
            },
            color: Colors.green,
          ),
          const SizedBox(width: 5),
          Obx(() {
            return LoadingButton(
                title: '收藏'.tr,
                icon: controller.isFavoritesShow.isTrue
                    ? PhosphorIcons.bookmarks_simple_fill
                    : PhosphorIcons.bookmark_simple,
                onPress: () async {
                  controller.switchFavorites();
                });
          }),
          const SizedBox(width: 5),
          SizedBox(
            width: 120,
            child: LoadingButton(
              title: '无法接收'.tr,
              icon: PhosphorIcons.circle_wavy_question,
              onPress: () async {
                final dialog = await showOkCancelAlertDialog(
                  context: Get.context!,
                  title: '关于无法接收'.tr,
                  message: '为什么接收不到'.tr,
                  isDestructiveAction: true,
                );
                if (dialog == OkCancelResult.ok) {
                  await controller.report();
                }
              },
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  ///message显示
  Widget _message(BuildContext context, int index) {
    // 原生广告
    if (controller.messageList[index] is NativeAd) {
      log('controller.isAdShowList.contains(index) = ${controller.isAdShowList.contains(index)}');
      var ad = Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: const Color(0xFF949494), width: 0.5),
          ),
          child: Column(
            children: [
              Obx(() {
                if (index < 20) {
                  return Container(
                    child: controller.isAdShowList.contains(index)
                        ? AdWidget(ad: controller.messageList[index])
                        : Text('加载中'.tr),
                    height: controller.messageList[index].factoryId == 'nativeBigAd'
                        ? 340.0
                        : 120.1, // big 340.0 small 120.0,
                    alignment: Alignment.center,
                  );
                }
                return Container(
                  child: AdWidget(ad: controller.messageList[index]),
                  height: controller.messageList[index].factoryId == 'nativeBigAd'
                      ? 340.0
                      : 120.0, // big 340.0 small 120.0,
                  alignment: Alignment.center,
                );
              }),
              //Text(controller.messageList[index].responseInfo.responseId)
            ],
          ),
        ),
      );
      return ad;
    }

    // 显示短信项目
    String smsNumber = controller.messageList[index]['smsNumber'];
    String url = controller.messageList[index]['url'];
    String lastTime = Tools.timeHandler(controller.messageList[index]['smsDate']);
    String project;
    if (url != '') {
      project = url;
    } else {
      if (double.tryParse(smsNumber) == null) {
        project = smsNumber;
      } else {
        if (smsNumber.length > 6) {
          project = '*' + smsNumber.substring(smsNumber.length - 6);
        } else {
          project = smsNumber;
        }
      }
    }

    /// message列表
    Widget message = Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Colors.grey[300],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.messageList[index]['smsContent'],
                style: GoogleFonts.getFont('Montserrat', textStyle: const TextStyle(fontSize: 15)),
                semanticsLabel: controller.messageList[index]['smsContent'],
              ),
              const SizedBox(
                height: 10,
              ),
              DefaultTextStyle(
                style: const TextStyle(color: Colors.grey, fontSize: 13.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          PhosphorIcons.envelope_simple_open,
                          size: 15,
                          color: Colors.grey,
                        ),
                        const SizedBox(
                          width: 2,
                        ),
                        Text(
                          project,
                          semanticsLabel: project,
                        )
                      ],
                    ),
                    Text(
                      lastTime,
                      semanticsLabel: lastTime,
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );

    return message;
  }

  ///上拉加载
  Future<void> _onLoad() async {
    controller.page = controller.page + 1;
    log('page = ${controller.page}');
    await controller.fetchMessageList(controller.currentPhoneInfo['phone_num'], page: controller.page);
    controller.refreshController.finishLoad(success: true);
  }

  ///下拉刷新
  Future<void> _onRefresh() async {
    //await Future.delayed(const Duration(milliseconds: 5000));
    await controller.fetchMessageList(controller.currentPhoneInfo['phone_num'], page: 1);
    controller.isMiddleBannerShow.value = false;
    controller.refreshController.finishRefresh(success: true);
    controller.page = 1;
  }

  /// 预告号码下面banner广告位
  Widget bannerAd() {
    const _insets = 16.0;
    double adWidth = MediaQuery.of(Get.context!).size.width - (2 * _insets);
    if (Admob().bannerInlineMediumRectangleAdSize != null) {
      return Center(
        child: Container(
          color: Colors.transparent,
          width: adWidth,
          height: Admob().bannerInlineMediumRectangleAdSize!.height.toDouble(),
          child: AdWidget(ad: Admob().bannerInlineMediumRectangleAd!),
        ),
      );
    } else {
      return const SizedBox();
    }
  }
}
